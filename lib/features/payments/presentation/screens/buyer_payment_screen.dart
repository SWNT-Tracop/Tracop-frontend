import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../core/config/payment_config.dart';
import '../../../../core/i18n/formats.dart';
import '../../../../core/i18n/strings.dart';
import '../../../../core/result/result.dart';
import '../../../../shared/widgets/option_selectors.dart';
import '../../../catalog/domain/lot_quantity.dart';
import '../../../ordering/domain/entities/order.dart';
import '../../../ordering/presentation/providers/order_provider.dart';
import '../../domain/entities/payment.dart';
import '../../domain/payment_permissions.dart';
import '../../domain/proof_file_rules.dart';
import '../../domain/proof_upload_cancellation.dart';
import '../payment_error_text.dart';
import '../providers/payment_provider.dart';
import '../widgets/payment_amount_summary.dart';
import '../widgets/payment_badges.dart';
import '../widgets/payment_dialogs.dart';
import '../widgets/payment_states.dart';
import '../widgets/payment_timeline.dart';
import '../widgets/proof_viewer.dart';

/// Selector de imagen inyectable (pruebas). Devuelve `null` si se cancela.
typedef ProofPicker = Future<XFile?> Function(ImageSource source);

Future<XFile?> _defaultPicker(ImageSource source) => ImagePicker().pickImage(
      source: source,
      maxWidth: 2560,
      maxHeight: 2560,
      imageQuality: 85,
    );

/// Pantalla de pago del comprador para un pedido (`/pedidos/:id/pago`).
class BuyerPaymentScreen extends ConsumerStatefulWidget {
  const BuyerPaymentScreen({super.key, required this.orderId, this.picker});
  final String orderId;
  final ProofPicker? picker;

  @override
  ConsumerState<BuyerPaymentScreen> createState() => _BuyerPaymentScreenState();
}

class _BuyerPaymentScreenState extends ConsumerState<BuyerPaymentScreen> {
  PaymentMethod? _method;
  bool _starting = false;
  String? _startError;

  /// Tras un rechazo, el comprador decide explícitamente iniciar otro pago.
  bool _startingOver = false;

  ProofFile? _proof;
  bool _uploading = false;
  String? _proofError;

  /// Carga en curso que el comprador puede cancelar.
  ProofUploadCancellation? _cancellation;

  /// Aviso neutro (no error) tras cancelar la carga.
  String? _proofNotice;

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  void _refreshAll() {
    ref.invalidate(orderPaymentProvider(widget.orderId));
    ref.invalidate(orderDetailProvider(widget.orderId));
    ref.invalidate(myOrdersProvider(null));
  }

  Future<void> _reloadPayment() async {
    ref.invalidate(orderPaymentProvider(widget.orderId));
    await ref
        .read(orderPaymentProvider(widget.orderId).future)
        .then<void>((_) {}, onError: (_) {});
  }

  Future<void> _start(Payment? rejected) async {
    final method = _method;
    if (method == null || _starting) return;
    setState(() {
      _starting = true;
      _startError = null;
    });
    final ids = ref.read(paymentAttemptIdsProvider);
    final paymentId =
        ids.idFor(widget.orderId, afterRejectedPaymentId: rejected?.id);
    final result = await ref.read(paymentRepositoryProvider).initiate(
          orderId: widget.orderId,
          paymentId: paymentId,
          method: method,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() {
          _starting = false;
          _startingOver = false;
        });
        _refreshAll();
      case Err(error: final failure):
        if (failure.code == 'idempotency_conflict') {
          ids.reset(widget.orderId, afterRejectedPaymentId: rejected?.id);
        }
        setState(() {
          _starting = false;
          _startError = paymentErrorText(failure);
        });
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_uploading) return;
    setState(() {
      _proofError = null;
      _proofNotice = null;
    });
    final XFile? file;
    try {
      file = await (widget.picker ?? _defaultPicker)(source);
    } catch (_) {
      if (mounted) setState(() => _proofError = PaymentStrings.pickerFailed);
      return;
    }
    if (file == null || !mounted) return; // Cancelado por el usuario.
    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      if (!mounted) return;
      setState(() => _proofError = paymentErrorText(const DomainFailure(
          statusCode: 0, code: 'proof_file_unreadable', message: '')));
      return;
    }
    if (!mounted) return;
    final check = checkProofBytes(bytes, maxBytes: PaymentConfig.proofMaxBytes);
    setState(() {
      switch (check) {
        case ProofAccepted(:final format):
          _proof = ProofFile(
              bytes: bytes, filename: proofFilename(format), format: format);
        case ProofRejected(:final code):
          _proof = null;
          _proofError = paymentErrorText(
              DomainFailure(statusCode: 0, code: code, message: ''));
      }
    });
  }

  Future<void> _upload(Payment payment) async {
    final proof = _proof;
    if (proof == null || _uploading) return;
    final cancellation = ProofUploadCancellation();
    setState(() {
      _uploading = true;
      _proofError = null;
      _proofNotice = null;
      _cancellation = cancellation;
    });
    final result = await ref
        .read(paymentRepositoryProvider)
        .uploadProof(payment.id, proof, cancellation: cancellation);
    if (!mounted) return;
    _cancellation = null;
    switch (result) {
      case Ok():
        setState(() {
          _uploading = false;
          _proof = null;
        });
        _snack(PaymentStrings.proofUploaded);
        _refreshAll();
      case Err(error: final failure)
          when failure.code == proofUploadCancelledCode:
        // Cancelar no es un error: se conserva la imagen para subirla luego.
        setState(() {
          _uploading = false;
          _proofNotice = PaymentStrings.uploadCancelled;
        });
      case Err(error: final failure):
        // Se conserva la imagen elegida para reintentar sin volver a buscarla.
        setState(() {
          _uploading = false;
          _proofError = paymentErrorText(failure);
        });
        if (failure.code == 'invalid_transition') _refreshAll();
    }
  }

  Future<void> _dispute(Payment payment) async {
    final repository = ref.read(paymentRepositoryProvider);
    final outcome = await showDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OpenDisputeDialog(
        onSubmit: (reason) =>
            repository.dispute(payment.id, payment.version, reason),
      ),
    );
    if (!mounted || outcome == null) return;
    if (outcome is DomainFailure) {
      await VersionConflictDialog.show(context);
    } else {
      _snack(PaymentStrings.disputeOpened);
    }
    _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final paymentAsync = ref.watch(orderPaymentProvider(widget.orderId));
    final textTheme = Theme.of(context).textTheme;

    Widget body;
    if (orderAsync.hasError && !orderAsync.hasValue) {
      body = PaymentErrorState(
        title: PaymentStrings.detailLoadError,
        message: orderAsync.error is DomainFailure
            ? paymentErrorText(orderAsync.error! as DomainFailure)
            : PaymentStrings.detailLoadError,
        onRetry: _refreshAll,
      );
    } else if (paymentAsync.hasError && !paymentAsync.hasValue) {
      body = PaymentErrorState(
        title: PaymentStrings.detailLoadError,
        message: paymentAsync.error is DomainFailure
            ? paymentErrorText(paymentAsync.error! as DomainFailure)
            : PaymentStrings.detailLoadError,
        onRetry: _refreshAll,
      );
    } else if (!orderAsync.hasValue || !paymentAsync.hasValue) {
      body = const PaymentLoadingSkeleton(rows: 4);
    } else {
      body = _content(orderAsync.requireValue, paymentAsync.requireValue);
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text(PaymentStrings.screenTitle,
                style: textTheme.headlineMedium?.copyWith(fontSize: 20)),
            const SizedBox(height: 2),
            Text(PaymentStrings.orderShort(widget.orderId),
                style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            body,
          ],
        ),
      ),
    );
  }

  Widget _content(OrderResponse order, Payment? payment) {
    final rejected = payment?.status == PaymentStatus.rejected ? payment : null;
    final orderPayable = payableOrderStatuses.contains(order.status);
    final available = PaymentPermissions.paymentsAvailable(
      releaseMode: kReleaseMode,
      hasPlaceholderData: PaymentConfig.hasPlaceholderAccountData,
    );
    // Lo que permitiría pagar (elegir medio, instrucciones, subir comprobante).
    final wantsToPay = payment == null ||
        payment.status == PaymentStatus.pending ||
        (rejected != null && _startingOver);
    final canPay = orderPayable && available;
    final showSelector =
        canPay && (payment == null || (rejected != null && _startingOver));
    final showPending =
        canPay && payment != null && payment.status == PaymentStatus.pending;
    final actions = payment == null
        ? const <PaymentAction>{}
        : PaymentPermissions.actionsFor(payment.status, 'buyer');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (payment != null) ...[
          _StatusCard(payment: payment),
          const SizedBox(height: 16),
        ],
        if (wantsToPay && !orderPayable && _isClosedOrder(order.status)) ...[
          const _Blocker(
            icon: Icons.do_not_disturb_on_outlined,
            title: PaymentStrings.orderNotPayableTitle,
            body: PaymentStrings.orderNotPayableBody,
            danger: true,
          ),
          const SizedBox(height: 16),
        ] else if (wantsToPay && orderPayable && !available) ...[
          const _Blocker(
            icon: Icons.pause_circle_outline,
            title: PaymentStrings.paymentsUnavailableTitle,
            body: PaymentStrings.paymentsUnavailableBody,
          ),
          const SizedBox(height: 16),
        ],
        _Section(
          title: PaymentStrings.orderSummary,
          child: _OrderSummary(order: order, payment: payment),
        ),
        const SizedBox(height: 16),
        if (showSelector)
          _methodSelector(rejected)
        else if (payment == null &&
            !orderPayable &&
            !_isClosedOrder(order.status))
          const PaymentEmptyState(
            icon: Icons.hourglass_empty,
            title: PaymentStrings.notPayableYet,
            body: '',
          )
        else if (actions.contains(PaymentAction.startNewPayment) &&
            !_startingOver &&
            canPay)
          FilledButton.icon(
            onPressed: () => setState(() {
              _startingOver = true;
              _method = null;
            }),
            icon: const Icon(Icons.replay),
            label: const Text(PaymentStrings.startNewPayment),
          ),
        if (showPending) ...[
          // Con un medio desconocido no se muestran datos de cuenta.
          if (payment.method != PaymentMethod.unknown) ...[
            _Section(
              title: PaymentStrings.instructionsTitle,
              child: _Instructions(method: payment.method, order: order),
            ),
            const SizedBox(height: 16),
          ],
          _Section(
            title: PaymentStrings.proofTitle,
            child: _proofUploader(payment),
          ),
        ],
        if (payment != null &&
            payment.hasProof &&
            !(rejected != null && _startingOver)) ...[
          const SizedBox(height: 16),
          _Section(
            title: PaymentStrings.proofTitle,
            child: ProofViewer(url: payment.proofUrl, onReload: _reloadPayment),
          ),
        ],
        if (payment != null) ...[
          const SizedBox(height: 16),
          _Section(
            title: null,
            child: PaymentTimeline(payment: payment),
          ),
        ],
        if (payment != null &&
            PaymentPermissions.canOpenDispute(payment, order.status)) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _dispute(payment),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.dangerStrong,
              side: const BorderSide(color: AppTheme.dangerStrong, width: 2),
            ),
            icon: const Icon(Icons.report_gmailerrorred_outlined),
            label: const Text(PaymentStrings.openDispute),
          ),
        ],
      ],
    );
  }

  /// Pedido que ya no volverá a ser pagable (cancelado, p. ej. por reserva
  /// vencida, o con otro pago ya verificado).
  static bool _isClosedOrder(String status) =>
      !payableOrderStatuses.contains(status) &&
      !const {'draft', 'requested', 'quoted'}.contains(status);

  Widget _methodSelector(Payment? rejected) {
    final method = _method;
    return _Section(
      title: PaymentStrings.chooseMethod,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OptionCircleSelector<PaymentMethod?>(
            value: method,
            onChanged: _starting
                ? (_) {}
                : (value) => setState(() {
                      _method = value;
                      _startError = null;
                    }),
            options: const [
              SelectorOption(
                value: PaymentMethod.transfer,
                label: PaymentStrings.methodTransfer,
                subtitle: PaymentStrings.transferHint,
                icon: Icons.account_balance_outlined,
              ),
              SelectorOption(
                value: PaymentMethod.nequi,
                label: PaymentStrings.methodNequi,
                subtitle: PaymentStrings.nequiHint,
                icon: Icons.phone_iphone,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(PaymentStrings.methodLocked,
              style: Theme.of(context).textTheme.bodySmall),
          if (_startError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_startError!,
                  style: const TextStyle(color: AppTheme.dangerStrong)),
            ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed:
                method == null || _starting ? null : () => _start(rejected),
            child: _starting
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.white)),
                    SizedBox(width: 12),
                    Text(PaymentStrings.starting),
                  ])
                : Text(method == null
                    ? PaymentStrings.chooseMethod
                    : PaymentStrings.continueWith(
                        PaymentStrings.method(method.wire))),
          ),
        ],
      ),
    );
  }

  Widget _proofUploader(Payment payment) {
    final proof = _proof;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          PaymentStrings.proofRequirements(
              PaymentConfig.proofMaxBytes ~/ (1024 * 1024)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (proof != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: Image.memory(
                Uint8List.fromList(proof.bytes),
                fit: BoxFit.contain,
                semanticLabel: PaymentStrings.proofImageLabel,
                errorBuilder: (_, __, ___) => const SizedBox(height: 40),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_proofError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_proofError!,
                style: const TextStyle(color: AppTheme.dangerStrong)),
          ),
        if (_proofNotice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              liveRegion: true,
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppTheme.mutedText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_proofNotice!,
                      style: const TextStyle(color: AppTheme.ink)),
                ),
              ]),
            ),
          ),
        if (proof != null)
          FilledButton.icon(
            onPressed: _uploading ? null : () => _upload(payment),
            icon: _uploading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.white))
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(_uploading
                ? PaymentStrings.uploadingProof
                : _proofError != null
                    ? PaymentStrings.retryUpload
                    : PaymentStrings.uploadProof),
          ),
        if (_uploading && _cancellation != null) ...[
          const SizedBox(height: 8),
          Tooltip(
            message: PaymentStrings.cancelUploadTooltip,
            child: OutlinedButton.icon(
              key: const Key('cancel-proof-upload'),
              onPressed: () => _cancellation?.cancel(),
              icon: const Icon(Icons.close),
              label: const Text(PaymentStrings.cancelUpload),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: _uploading ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text(PaymentStrings.chooseFromGallery),
          ),
          OutlinedButton.icon(
            onPressed: _uploading ? null : () => _pick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text(PaymentStrings.takePhoto),
          ),
        ]),
      ],
    );
  }
}

class _Blocker extends StatelessWidget {
  const _Blocker({
    required this.icon,
    required this.title,
    required this.body,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String body;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final foreground = danger ? AppTheme.dangerText : AppTheme.warningText;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: danger ? AppTheme.dangerSurface : AppTheme.warningSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSurface),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: foreground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text(body, style: TextStyle(color: foreground)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Text(title!,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.payment});
  final Payment payment;

  String get _body => payment.disputeResolved
      ? PaymentStrings.statusDisputeResolvedBody
      : _statusBody;

  String get _statusBody => switch (payment.status) {
        PaymentStatus.pending => PaymentStrings.statusPendingBody,
        PaymentStatus.proofUploaded => PaymentStrings.statusProofUploadedBody,
        PaymentStatus.verified => PaymentStrings.statusVerifiedBody,
        PaymentStatus.held => PaymentStrings.statusHeldBody,
        PaymentStatus.rejected => PaymentStrings.statusRejectedBody,
        PaymentStatus.disputed => PaymentStrings.statusDisputedBody,
        PaymentStatus.settled => PaymentStrings.statusSettledBody,
        PaymentStatus.refunded => PaymentStrings.statusRefundedBody,
        PaymentStatus.unknown => PaymentStrings.statusUnknownBody,
      };

  @override
  Widget build(BuildContext context) {
    final style = PaymentStatusBadge.styleForPayment(payment);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(PaymentStrings.currentStatus,
              style: TextStyle(color: style.foreground, fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            Icon(style.icon, color: style.foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  PaymentStrings.statusLabel(payment.statusCode,
                      disputeResolved: payment.disputeResolved),
                  style: TextStyle(
                      color: style.foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
            PaymentMethodBadge(
                method: payment.method, wire: payment.methodCode),
          ]),
          const SizedBox(height: 8),
          Text(_body, style: TextStyle(color: style.foreground)),
          if (payment.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Text(PaymentStrings.rejectionReason,
                style: TextStyle(
                    color: style.foreground, fontWeight: FontWeight.w700)),
            Text(payment.rejectionReason!,
                style: TextStyle(color: style.foreground)),
          ],
          if (payment.disputeReason != null) ...[
            const SizedBox(height: 10),
            Text(PaymentStrings.disputeReason,
                style: TextStyle(
                    color: style.foreground, fontWeight: FontWeight.w700)),
            Text(payment.disputeReason!,
                style: TextStyle(color: style.foreground)),
          ],
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order, required this.payment});
  final OrderResponse order;
  final Payment? payment;

  @override
  Widget build(BuildContext context) {
    // Con un pago existente se muestran sus montos (los que se cobran).
    final payment = this.payment;
    final subtotal = payment?.subtotal ?? _int(order.amounts.subtotal);
    final freight = payment?.freight ?? _int(order.amounts.freight);
    final total = payment?.total ?? _int(order.amounts.total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(PaymentStrings.products,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        for (final line in order.lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.eco_outlined, size: 18, color: AppTheme.forest),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${PaymentStrings.lotShort(line.lotId)} · '
                  '${formatQuantityMilli(line.quantityMilli)} ${line.unit} × '
                  '${AppFormats.copText(line.unitPrice)}',
                  style: const TextStyle(color: AppTheme.ink),
                ),
              ),
            ]),
          ),
        const SizedBox(height: 10),
        PaymentAmountSummary(
          subtotal: subtotal,
          freight: freight,
          total: total,
          caption: payment == null
              ? PaymentStrings.amountsFromOrder
              : PaymentStrings.amountsFromPayment,
        ),
      ],
    );
  }

  static int _int(String value) {
    try {
      return parseMoney(value);
    } on FormatException {
      return 0;
    }
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions({required this.method, required this.order});
  final PaymentMethod method;
  final OrderResponse order;

  @override
  Widget build(BuildContext context) {
    final rows = method == PaymentMethod.nequi
        ? [
            (PaymentStrings.nequiNumber, PaymentConfig.nequiNumber),
            (PaymentStrings.accountHolder, PaymentConfig.accountHolder),
          ]
        : [
            (PaymentStrings.bank, PaymentConfig.bankName),
            (PaymentStrings.accountType, PaymentConfig.bankAccountType),
            (PaymentStrings.accountNumber, PaymentConfig.bankAccountNumber),
            (PaymentStrings.accountHolder, PaymentConfig.accountHolder),
            (PaymentStrings.accountHolderId, PaymentConfig.accountHolderId),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(method == PaymentMethod.nequi
            ? PaymentStrings.nequiSteps
            : PaymentStrings.transferSteps),
        const SizedBox(height: 10),
        if (PaymentConfig.hasPlaceholderAccountData)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            ),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warningIcon),
              SizedBox(width: 10),
              Expanded(
                child: Text(PaymentStrings.placeholderWarning,
                    style: TextStyle(color: AppTheme.warningText)),
              ),
            ]),
          ),
        for (final (label, value) in rows)
          Row(children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(color: AppTheme.mutedText)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppTheme.ink, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              tooltip: '${PaymentStrings.copy} $label',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(PaymentStrings.copied(label))));
              },
            ),
          ]),
        const SizedBox(height: 6),
        Text(
          '${PaymentStrings.referenceHint} '
          '(${PaymentStrings.orderShort(order.id)})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
