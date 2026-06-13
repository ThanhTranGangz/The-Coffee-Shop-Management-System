import express from 'express';
import http from 'http';
import { WebSocketServer } from 'ws';
import path from 'path';

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

app.use(express.json());

// Serve static web folder
app.use(express.static('web'));

// Shared state mimicking BrewStateService.java
const menu = [
  { id: "m1", name: "Traditional Black Coffee (Café Đen)", category: "Coffee", price: 29000, description: "Bold, dark-roasted Vietnamese coffee beans brewed with a traditional phin filter.", availableSizes: ["S", "M", "L"] },
  { id: "m2", name: "Vietnamese Milk Coffee (Café Sữa Đá)", category: "Coffee", price: 35000, description: "Traditional Vietnamese drip coffee sweetened with rich condensed milk, served over ice.", availableSizes: ["S", "M", "L"] },
  { id: "m3", name: "Salted Cream Coffee (Café Muối)", category: "Coffee", price: 45000, description: "A unique combination of bold coffee with sweet condensed milk, topped with a velvety, slightly salty whipping cream.", availableSizes: ["S", "M"] },
  { id: "m4", name: "Coconut Cold Brew", category: "Coffee", price: 49000, description: "Slow-steeped cold brew coffee paired with sweet and aromatic fresh coconut water.", availableSizes: ["M", "L"] },
  { id: "m5", name: "Peach Tea Lemongrass (Trà Đào Cam Sả)", category: "Tea", price: 45000, description: "Refreshing black tea infused with peach syrup, fresh orange juice, and a fragrant stalk of lemongrass.", availableSizes: ["M", "L"] },
  { id: "m6", name: "Matcha Latte", category: "Specialty", price: 49000, description: "Premium Japanese Uji matcha whisked with warm or iced milk and a hint of sweetness.", availableSizes: ["S", "M", "L"] },
  { id: "m7", name: "Oolong Milk Tea Cordial", category: "Tea", price: 45000, description: "Roasted oolong tea leaves blended with gourmet milk powder, topped with cream cheese cap.", availableSizes: ["M", "L"] },
  { id: "m8", name: "Butter Croissant", category: "Pastry", price: 29000, description: "Flaky, buttery, golden French pastry baked fresh daily.", availableSizes: ["S"] },
  { id: "m9", name: "Tiramisu Slice", category: "Pastry", price: 45000, description: "Espresso-soaked ladyfingers nested in a light and airy mascarpone cream, dusted with cocoa powder.", availableSizes: ["S"] }
];

const tables = [
  { id: "t1", name: "Table 1", zone: "Ground Floor", status: "empty", capacity: 2, activeOrderId: null },
  { id: "t2", name: "Table 2", zone: "Ground Floor", status: "empty", capacity: 2, activeOrderId: null },
  { id: "t3", name: "Table 3", zone: "Ground Floor", status: "empty", capacity: 4, activeOrderId: null },
  { id: "t4", name: "Table 4", zone: "Ground Floor", status: "empty", capacity: 4, activeOrderId: null },
  { id: "t5", name: "Table 5", zone: "Terrace", status: "empty", capacity: 2, activeOrderId: null },
  { id: "t6", name: "Table 6", zone: "Terrace", status: "empty", capacity: 2, activeOrderId: null },
  { id: "t7", name: "Table 7", zone: "Terrace", status: "empty", capacity: 4, activeOrderId: null },
  { id: "t8", name: "Table 8", zone: "Upper Floor", status: "empty", capacity: 2, activeOrderId: null },
  { id: "t9", name: "Table 9", zone: "Upper Floor", status: "empty", capacity: 4, activeOrderId: null },
  { id: "t10", name: "Table 10", zone: "Upper Floor", status: "empty", capacity: 4, activeOrderId: null },
  { id: "t11", name: "Table 11", zone: "Upper Floor", status: "empty", capacity: 6, activeOrderId: null },
  { id: "t12", name: "Table 12", zone: "Upper Floor", status: "empty", capacity: 8, activeOrderId: null }
];

const orders = [];
let orderCounter = 1001;

function broadcast(type, payload) {
  const json = JSON.stringify({ type, payload });
  wss.clients.forEach(client => {
    if (client.readyState === 1) {
      client.send(json);
    }
  });
}

function updateTableStatus(tableId) {
  const table = tables.find(t => t.id === tableId);
  if (!table) return;

  const activeOrders = orders.filter(o => o.tableId === tableId && o.status !== 'Served');
  if (activeOrders.length === 0) {
    table.status = 'empty';
    table.activeOrderId = null;
  } else {
    const hasReadyItems = activeOrders.some(o => o.items.some(it => it.status === 'Ready'));
    table.status = hasReadyItems ? 'ready_to_serve' : 'serving';
    table.activeOrderId = activeOrders[0].id;
  }
}

function updateOrderAggregateStatus(order) {
  if (order.items.length === 0) return "Pending";
  const allServed = order.items.every(it => it.status === "Served");
  if (allServed) return "Served";

  const anyActive = order.items.some(it => ["Ready", "Preparing", "Served"].includes(it.status));
  return anyActive ? "Preparing" : "Pending";
}

// REST Endpoints
app.get('/api/menu', (req, res) => res.json(menu));
app.get('/api/tables', (req, res) => res.json(tables));
app.get('/api/orders', (req, res) => res.json(orders));

app.post('/api/orders', (req, res) => {
  const { tableId, items, notes } = req.body;
  const table = tables.find(t => t.id === tableId);
  if (!table) return res.status(404).json({ error: 'Table not found' });

  const newOrderId = 'order_' + Date.now();
  const orderNumber = orderCounter++;

  const mappedItems = items.map((it, idx) => ({
    id: `item_${Date.now()}_${idx}`,
    menuItemId: it.menuItemId,
    name: it.name,
    price: it.price,
    quantity: it.quantity,
    customization: it.customization || { size: 'M' },
    notes: it.notes || '',
    status: 'Pending'
  }));

  const totalAmount = mappedItems.reduce((acc, it) => acc + (it.price * it.quantity), 0);
  const nowIso = new Date().toISOString();

  const newOrder = {
    id: newOrderId,
    tableId,
    tableName: table.name,
    orderNumber,
    items: mappedItems,
    status: 'Pending',
    createdAt: nowIso,
    updatedAt: nowIso,
    notes: notes || '',
    totalAmount
  };

  orders.push(newOrder);
  updateTableStatus(tableId);

  broadcast('order_created', newOrder);
  broadcast('table_updated', table);

  res.status(201).json(newOrder);
});

app.post('/api/tables/move', (req, res) => {
  const { sourceTableId, targetTableId } = req.body;
  const sourceTable = tables.find(t => t.id === sourceTableId);
  const targetTable = tables.find(t => t.id === targetTableId);

  if (!sourceTable || !targetTable) return res.status(404).json({ error: 'Table not found' });
  if (targetTable.status !== 'empty') return res.status(400).json({ error: 'Target occupied' });

  const activeOrders = orders.filter(o => o.tableId === sourceTableId && o.status !== 'Served');
  if (activeOrders.length === 0) return res.status(400).json({ error: 'No active orders on source' });

  const nowIso = new Date().toISOString();
  activeOrders.forEach(o => {
    o.tableId = targetTableId;
    o.tableName = targetTable.name;
    o.updatedAt = nowIso;
  });

  updateTableStatus(sourceTableId);
  updateTableStatus(targetTableId);

  broadcast('table_moved', { sourceTableId, targetTableId });
  broadcast('table_updated', sourceTable);
  broadcast('table_updated', targetTable);
  activeOrders.forEach(o => broadcast('order_updated', o));

  res.json({ message: 'Moved successfully' });
});

app.post('/api/tables/merge', (req, res) => {
  const { sourceTableId, targetTableId } = req.body;
  const sourceTable = tables.find(t => t.id === sourceTableId);
  const targetTable = tables.find(t => t.id === targetTableId);

  if (!sourceTable || !targetTable) return res.status(404).json({ error: 'Table not found' });

  const sourceOrders = orders.filter(o => o.tableId === sourceTableId && o.status !== 'Served');
  const targetOrders = orders.filter(o => o.tableId === targetTableId && o.status !== 'Served');

  if (sourceOrders.length === 0) return res.status(400).json({ error: 'Source has no order' });

  const nowIso = new Date().toISOString();

  if (targetOrders.length === 0) {
    sourceOrders.forEach(o => {
      o.tableId = targetTableId;
      o.tableName = targetTable.name;
      o.updatedAt = nowIso;
    });
  } else {
    const primaryOrder = targetOrders[0];
    sourceOrders.forEach(so => {
      so.items.forEach(it => {
        const itemCopy = {
          ...it,
          id: `item_merged_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`
        };
        primaryOrder.items.push(itemCopy);
      });
      if (so.notes) {
        primaryOrder.notes = (primaryOrder.notes ? primaryOrder.notes + ' / ' : '') + `[Merged from ${sourceTable.name}]: ${so.notes}`;
      }
      so.status = 'Served';
      so.items.forEach(it => it.status = 'Served');
      so.updatedAt = nowIso;
    });

    primaryOrder.totalAmount = primaryOrder.items.reduce((acc, it) => acc + (it.price * it.quantity), 0);
    primaryOrder.status = updateOrderAggregateStatus(primaryOrder);
    primaryOrder.updatedAt = nowIso;

    broadcast('order_updated', primaryOrder);
  }

  updateTableStatus(sourceTableId);
  updateTableStatus(targetTableId);

  broadcast('table_merged', { sourceTableId, targetTableId });
  broadcast('table_updated', sourceTable);
  broadcast('table_updated', targetTable);
  sourceOrders.forEach(o => broadcast('order_updated', o));

  res.json({ message: 'Merged successfully' });
});

app.post('/api/tables/:tableId/checkout', (req, res) => {
  const { tableId } = req.params;
  const table = tables.find(t => t.id === tableId);
  if (!table) return res.status(404).json({ error: 'Table not found' });

  const tableOrders = orders.filter(o => o.tableId === tableId && o.status !== 'Served');
  const nowIso = new Date().toISOString();

  tableOrders.forEach(o => {
    o.status = 'Served';
    o.items.forEach(it => it.status = 'Served');
    o.updatedAt = nowIso;
    broadcast('order_completed', o);
  });

  updateTableStatus(tableId);
  broadcast('table_updated', table);

  res.json({ message: 'Checkout successfully', table });
});

app.put('/api/orders/:orderId/items/:itemId', (req, res) => {
  const { orderId, itemId } = req.params;
  const { status } = req.body;

  const order = orders.find(o => o.id === orderId);
  if (!order) return res.status(404).json({ error: 'Order not found' });

  const item = order.items.find(it => it.id === itemId);
  if (!item) return res.status(404).json({ error: 'Item not found' });

  item.status = status;
  order.status = updateOrderAggregateStatus(order);
  order.updatedAt = new Date().toISOString();

  updateTableStatus(order.tableId);

  broadcast('order_updated', order);
  broadcast('table_updated', tables.find(t => t.id === order.tableId));

  res.json(order);
});

app.put('/api/orders/:orderId/status', (req, res) => {
  const { orderId } = req.params;
  const { status } = req.body;

  const order = orders.find(o => o.id === orderId);
  if (!order) return res.status(404).json({ error: 'Order not found' });

  order.status = status;
  order.items.forEach(item => {
    if (status === 'Served') item.status = 'Served';
    else if (status === 'Preparing' && item.status === 'Pending') item.status = 'Preparing';
    else if (status === 'Ready' && ['Pending', 'Preparing'].includes(item.status)) item.status = 'Ready';
  });

  order.updatedAt = new Date().toISOString();
  updateTableStatus(order.tableId);

  broadcast('order_updated', order);
  broadcast('table_updated', tables.find(t => t.id === order.tableId));

  res.json(order);
});

// Fallback HTML router
app.get('*', (req, res) => {
  res.sendFile(path.join(process.cwd(), 'web', 'index.html'));
});

// WebSockets link
wss.on('connection', ws => {
  console.log('WS Monitor established.');
  ws.send(JSON.stringify({
    type: 'init_state',
    payload: { menu, tables, orders }
  }));
});

server.listen(3000, '0.0.0.0', () => {
    console.log('Synchronizer ready on http://localhost:3000');
});
