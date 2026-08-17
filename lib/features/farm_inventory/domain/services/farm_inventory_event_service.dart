import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_factory.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';

class FarmInventoryEventService {
  const FarmInventoryEventService({
    this.eventFactory = const AtlasEventFactory(),
  });

  final AtlasEventFactory eventFactory;

  Future<void> publishItemCreated({
    required String farmName,
    required FarmInventoryData item,
    required double totalInventoryValue,
  }) async {
    final events = <AtlasEvent>[
      _itemEvent(
        type: AtlasEventType.inventoryItemCreated,
        title: 'Produto cadastrado no estoque',
        farmName: farmName,
        item: item,
        totalInventoryValue: totalInventoryValue,
      ),
      ..._stockAlertEvents(
        farmName: farmName,
        item: item,
        totalInventoryValue: totalInventoryValue,
      ),
    ];

    await AtlasEventBus.instance.publishAll(events);
  }

  Future<void> publishItemUpdated({
    required String farmName,
    required FarmInventoryData previousItem,
    required FarmInventoryData updatedItem,
    required double totalInventoryValue,
    String reason = 'Produto atualizado',
  }) async {
    final events = <AtlasEvent>[
      _itemEvent(
        type: AtlasEventType.inventoryItemUpdated,
        title: reason,
        farmName: farmName,
        item: updatedItem,
        totalInventoryValue: totalInventoryValue,
        extraPayload: <String, dynamic>{
          'previousName': previousItem.name,
          'previousCategory': previousItem.category,
          'previousQuantity': previousItem.quantity,
          'previousMinimumQuantity': previousItem.minimumQuantity,
          'previousUnitValue': previousItem.unitValue,
          'quantityVariation': updatedItem.quantity - previousItem.quantity,
        },
      ),
      ..._stockAlertEvents(
        farmName: farmName,
        item: updatedItem,
        totalInventoryValue: totalInventoryValue,
      ),
    ];

    await AtlasEventBus.instance.publishAll(events);
  }

  Future<void> publishItemDeleted({
    required String farmName,
    required FarmInventoryData deletedItem,
    required double totalInventoryValue,
  }) async {
    final event = _itemEvent(
      type: AtlasEventType.inventoryItemUpdated,
      title: 'Produto removido do estoque',
      farmName: farmName,
      item: deletedItem,
      totalInventoryValue: totalInventoryValue,
      priority: AtlasEventPriority.normal,
      extraPayload: const <String, dynamic>{'deleted': true},
    );

    await AtlasEventBus.instance.publish(event);
  }

  AtlasEvent _itemEvent({
    required AtlasEventType type,
    required String title,
    required String farmName,
    required FarmInventoryData item,
    required double totalInventoryValue,
    AtlasEventPriority? priority,
    Map<String, dynamic> extraPayload = const <String, dynamic>{},
  }) {
    return eventFactory.create(
      type: type,
      sourceModule: 'farm_inventory',
      title: title,
      description:
          '${item.name}: ${item.quantity.toStringAsFixed(2)} '
          '${item.unit} em estoque.',
      priority: priority ?? _priorityForItem(item),
      farmId: farmName,
      farmName: farmName,
      entityId: item.id,
      entityType: 'farm_inventory_item',
      payload: <String, dynamic>{
        'name': item.name,
        'category': item.category,
        'quantity': item.quantity,
        'minimumQuantity': item.minimumQuantity,
        'unit': item.unit,
        'unitValue': item.unitValue,
        'totalValue': item.totalValue,
        'totalInventoryValue': totalInventoryValue,
        'expirationDate': item.expirationDate,
        'supplier': item.supplier,
        'batch': item.batch,
        'notes': item.notes,
        ...extraPayload,
      },
      tags: <String>[
        'inventory',
        _normalizeTag(item.category),
        item.quantity <= 0
            ? 'out_of_stock'
            : item.hasLowStock
            ? 'low_stock'
            : 'available',
      ],
    );
  }

  List<AtlasEvent> _stockAlertEvents({
    required String farmName,
    required FarmInventoryData item,
    required double totalInventoryValue,
  }) {
    if (item.quantity <= 0) {
      return <AtlasEvent>[
        eventFactory.create(
          type: AtlasEventType.inventoryOutOfStock,
          sourceModule: 'farm_inventory',
          title: 'Produto esgotado',
          description: '${item.name} está sem estoque na fazenda $farmName.',
          priority: AtlasEventPriority.critical,
          farmId: farmName,
          farmName: farmName,
          entityId: item.id,
          entityType: 'farm_inventory_item',
          payload: <String, dynamic>{
            'name': item.name,
            'category': item.category,
            'quantity': item.quantity,
            'minimumQuantity': item.minimumQuantity,
            'unit': item.unit,
            'unitValue': item.unitValue,
            'totalInventoryValue': totalInventoryValue,
            'supplier': item.supplier,
          },
          tags: <String>[
            'inventory',
            'out_of_stock',
            'critical',
            _normalizeTag(item.category),
          ],
        ),
      ];
    }

    if (item.hasLowStock) {
      return <AtlasEvent>[
        eventFactory.create(
          type: AtlasEventType.inventoryLowStock,
          sourceModule: 'farm_inventory',
          title: 'Estoque baixo',
          description:
              '${item.name} possui ${item.quantity.toStringAsFixed(2)} '
              '${item.unit}, abaixo ou igual ao mínimo de '
              '${item.minimumQuantity.toStringAsFixed(2)} ${item.unit}.',
          priority: AtlasEventPriority.high,
          farmId: farmName,
          farmName: farmName,
          entityId: item.id,
          entityType: 'farm_inventory_item',
          payload: <String, dynamic>{
            'name': item.name,
            'category': item.category,
            'quantity': item.quantity,
            'minimumQuantity': item.minimumQuantity,
            'unit': item.unit,
            'unitValue': item.unitValue,
            'totalInventoryValue': totalInventoryValue,
            'supplier': item.supplier,
          },
          tags: <String>[
            'inventory',
            'low_stock',
            'attention',
            _normalizeTag(item.category),
          ],
        ),
      ];
    }

    return const <AtlasEvent>[];
  }

  AtlasEventPriority _priorityForItem(FarmInventoryData item) {
    if (item.quantity <= 0) {
      return AtlasEventPriority.critical;
    }

    if (item.hasLowStock) {
      return AtlasEventPriority.high;
    }

    return AtlasEventPriority.normal;
  }

  String _normalizeTag(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}
