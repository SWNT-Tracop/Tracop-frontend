const backofficeMetricsFixture = <String, dynamic>{
  'generatedAt': '2026-11-25T15:00:00.000Z',
  'paidOrdersTotalCop': '90000',
  'lotsByStatus': {'published': 3, 'sold_out': 1},
  'payments': {
    'proofsAwaitingReview': 1,
    'openDisputes': 0,
  },
  'notificationDeliveries': {'pending': 0, 'sent': 12, 'failed': 1},
  'outbox': {'pending': 0, 'deadLettered': 0},
};

const backofficeCategoriesFixture = <dynamic>[
  {'id': 'category-1', 'name': 'Hortalizas', 'depth': 1},
];

const backofficeProductsFixture = <dynamic>[
  {
    'id': 'product-1',
    'categoryId': 'category-1',
    'name': 'Tomate chonto',
    'unit': 'kg',
    'status': 'approved',
    'attributes': {},
  },
];

const backofficeAuditFixture = <dynamic>[
  {
    'id': 'audit-1',
    'action': 'parameter.update',
    'entity': 'parameter',
    'entityId': 'order.freight_cop',
    'actorRole': 'admin',
    'at': '2026-11-25T15:00:00.000Z',
    'before': {'value': '15000'},
    'after': {'value': '18000'},
  },
];
