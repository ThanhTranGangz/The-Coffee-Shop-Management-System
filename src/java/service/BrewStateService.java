package service;

import dao.MenuDAO;
import dao.TableDAO;
import dao.OrderDAO;
import model.*;
import websocket.BrewWebSocketHandler;

import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

public class BrewStateService {
    private final MenuDAO menuDAO;
    private final TableDAO tableDAO;
    private final OrderDAO orderDAO;
    private final BrewWebSocketHandler webSocketHandler;
    private final AtomicInteger orderCounter = new AtomicInteger(100);

    public BrewStateService(MenuDAO menuDAO, TableDAO tableDAO, OrderDAO orderDAO, BrewWebSocketHandler webSocketHandler) {
        this.menuDAO = menuDAO;
        this.tableDAO = tableDAO;
        this.orderDAO = orderDAO;
        this.webSocketHandler = webSocketHandler;
        
        // Seed initial order for Table 3 to make the app look dynamic out of the box
        seedInitialOrder();
    }

    private void seedInitialOrder() {
        try {
            Table table = tableDAO.getById("t3");
            if (table != null) {
                List<Map<String, Object>> seedItems = new ArrayList<>();
                
                Map<String, Object> item1 = new HashMap<>();
                item1.put("menuItemId", "m2");
                item1.put("quantity", 2L);
                item1.put("notes", "Less ice, please.");
                Map<String, Object> cust1 = new HashMap<>();
                cust1.put("size", "L");
                cust1.put("sugar", "100%");
                cust1.put("ice", "50%");
                item1.put("customization", cust1);
                
                Map<String, Object> item2 = new HashMap<>();
                item2.put("menuItemId", "m8");
                item2.put("quantity", 1L);
                item2.put("notes", "Warm it up.");
                Map<String, Object> cust2 = new HashMap<>();
                cust2.put("size", "S");
                cust2.put("sugar", "100%");
                cust2.put("ice", "100%");
                item2.put("customization", cust2);

                seedItems.add(item1);
                seedItems.add(item2);

                placeOrder("t3", seedItems, "Welcome guests");
            }
        } catch (Exception e) {
            System.err.println("Failed to seed initial order: " + e.getMessage());
        }
    }

    public List<MenuItem> getMenu() {
        return menuDAO.getAll();
    }

    public List<Table> getTables() {
        return tableDAO.getAll();
    }

    public List<Order> getOrders() {
        return orderDAO.getAll();
    }

    /**
     * Places a new order for a table
     */
    public synchronized Order placeOrder(String tableId, List<Map<String, Object>> rawItems, String notes) {
        Table table = tableDAO.getById(tableId);
        if (table == null) {
            throw new IllegalArgumentException("Table " + tableId + " not found.");
        }

        String orderId = "ord-" + UUID.randomUUID().toString().substring(0, 8);
        String timestamp = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());

        List<OrderItem> orderItems = new ArrayList<>();
        int totalAmount = 0;

        for (Map<String, Object> rawItem : rawItems) {
            String menuItemId = (String) rawItem.get("menuItemId");
            MenuItem menuItem = menuDAO.getById(menuItemId);
            if (menuItem == null) continue;

            int quantity = 1;
            if (rawItem.get("quantity") instanceof Number) {
                quantity = ((Number) rawItem.get("quantity")).intValue();
            }

            // Parse optional customizations
            CustomizationOptions custom = new CustomizationOptions();
            if (rawItem.get("customization") instanceof Map) {
                Map<String, Object> rawCust = (Map<String, Object>) rawItem.get("customization");
                custom.setSize((String) rawCust.getOrDefault("size", "M"));
                custom.setSugar((String) rawCust.getOrDefault("sugar", "100%"));
                custom.setIce((String) rawCust.getOrDefault("ice", "100%"));
            }

            String itemNotes = (String) rawItem.getOrDefault("notes", "");
            int itemPrice = menuItem.getPrice();
            
            // Adjust price slightly based on size premium
            if ("L".equalsIgnoreCase(custom.getSize())) {
                itemPrice += 6000;
            } else if ("S".equalsIgnoreCase(custom.getSize())) {
                itemPrice = Math.max(10000, itemPrice - 4000);
            }

            int subtotal = itemPrice * quantity;
            totalAmount += subtotal;

            String sItemId = "item-" + UUID.randomUUID().toString().substring(0, 8);
            orderItems.add(new OrderItem(
                sItemId, menuItemId, menuItem.getName(), itemPrice, quantity, custom, itemNotes, "Pending"
            ));
        }

        Order order = new Order(
            orderId, tableId, table.getName(), orderCounter.incrementAndGet(),
            orderItems, "Pending", timestamp, timestamp, notes, totalAmount
        );

        orderDAO.create(order);

        // Link table to order
        table.setStatus("serving");
        table.setActiveOrderId(orderId);
        tableDAO.update(table);

        // Notify client side
        notifyStateChange();

        return order;
    }

    /**
     * Updates individual item status in the kitchen display
     */
    public synchronized void updateItemStatus(String orderId, String itemId, String newStatus) {
        Order order = orderDAO.getById(orderId);
        if (order == null) return;

        boolean itemUpdated = false;
        for (OrderItem item : order.getItems()) {
            if (item.getId().equals(itemId)) {
                item.setStatus(newStatus);
                itemUpdated = true;
                break;
            }
        }

        if (itemUpdated) {
            recalculateAggregatedOrderStatus(order);
            order.setUpdatedAt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
            orderDAO.update(order);
            
            // Update table status sync if needed
            Table table = tableDAO.getById(order.getTableId());
            if (table != null) {
                if ("Ready".equalsIgnoreCase(order.getStatus())) {
                    table.setStatus("ready_to_serve");
                } else if ("Served".equalsIgnoreCase(order.getStatus())) {
                    table.setStatus("serving");
                }
                tableDAO.update(table);
            }

            notifyStateChange();
        }
    }

    /**
     * Updates entire order status (cascades status to items)
     */
    public synchronized void updateOrderStatus(String orderId, String newStatus) {
        Order order = orderDAO.getById(orderId);
        if (order == null) return;

        order.setStatus(newStatus);
        order.setUpdatedAt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));

        // Cascade to children order items
        for (OrderItem item : order.getItems()) {
            item.setStatus(newStatus);
        }
        orderDAO.update(order);

        Table table = tableDAO.getById(order.getTableId());
        if (table != null) {
            if ("Ready".equalsIgnoreCase(newStatus)) {
                table.setStatus("ready_to_serve");
            } else {
                table.setStatus("serving");
            }
            tableDAO.update(table);
        }

        notifyStateChange();
    }

    /**
     * Helper to compute order's aggregate status based on children items
     */
    private void recalculateAggregatedOrderStatus(Order order) {
        if (order.getItems().isEmpty()) return;

        int pendingCount = 0;
        int preparingCount = 0;
        int readyCount = 0;
        int servedCount = 0;

        for (OrderItem item : order.getItems()) {
            switch (item.getStatus()) {
                case "Pending": pendingCount++; break;
                case "Preparing": preparingCount++; break;
                case "Ready": readyCount++; break;
                case "Served": servedCount++; break;
            }
        }

        int total = order.getItems().size();
        if (servedCount == total) {
            order.setStatus("Served");
        } else if (readyCount + servedCount == total) {
            order.setStatus("Ready");
        } else if (preparingCount > 0 || readyCount > 0 || servedCount > 0) {
            order.setStatus("Preparing");
        } else {
            order.setStatus("Pending");
        }
    }

    /**
     * Moves an active dining table billing sequence of an order to an empty table
     */
    public synchronized void moveTable(String sourceId, String targetId) {
        Table source = tableDAO.getById(sourceId);
        Table target = tableDAO.getById(targetId);

        if (source == null || target == null) return;
        if (source.getActiveOrderId() == null) return;

        // Ensure target is empty, otherwise we merge instead
        if (target.getActiveOrderId() != null) {
            mergeTables(sourceId, targetId);
            return;
        }

        String orderId = source.getActiveOrderId();
        Order order = orderDAO.getById(orderId);
        if (order != null) {
            order.setTableId(targetId);
            order.setTableName(target.getName());
            orderDAO.update(order);
        }

        target.setStatus(source.getStatus());
        target.setActiveOrderId(orderId);
        tableDAO.update(target);

        source.setStatus("empty");
        source.setActiveOrderId(null);
        tableDAO.update(source);

        notifyStateChange();
    }

    /**
     * Merges items from a source table into a destination table's active order
     */
    public synchronized void mergeTables(String sourceId, String targetId) {
        Table source = tableDAO.getById(sourceId);
        Table target = tableDAO.getById(targetId);

        if (source == null || target == null) return;
        if (source.getActiveOrderId() == null) return;

        String sourceOrderId = source.getActiveOrderId();
        String targetOrderId = target.getActiveOrderId();

        if (targetOrderId == null) {
            // Target is empty - just perform regular move
            moveTable(sourceId, targetId);
            return;
        }

        Order sourceOrder = orderDAO.getById(sourceOrderId);
        Order targetOrder = orderDAO.getById(targetOrderId);

        if (sourceOrder != null && targetOrder != null) {
            // Merging order items list
            for (OrderItem sItem : sourceOrder.getItems()) {
                // Look for an identical item in target to merge quantities
                boolean merged = false;
                for (OrderItem tItem : targetOrder.getItems()) {
                    if (tItem.getMenuItemId().equals(sItem.getMenuItemId()) &&
                        tItem.getCustomization().getSize().equals(sItem.getCustomization().getSize()) &&
                        tItem.getCustomization().getSugar().equals(sItem.getCustomization().getSugar()) &&
                        tItem.getCustomization().getIce().equals(sItem.getCustomization().getIce()) &&
                        tItem.getStatus().equals(sItem.getStatus())) {
                        
                        tItem.setQuantity(tItem.getQuantity() + sItem.getQuantity());
                        merged = true;
                        break;
                    }
                }
                if (!merged) {
                    // Unique item, generate a new id and append
                    sItem.setId("item-" + UUID.randomUUID().toString().substring(0, 8));
                    targetOrder.getItems().add(sItem);
                }
            }

            // Append order notes
            String combinedNotes = targetOrder.getNotes();
            if (combinedNotes == null) combinedNotes = "";
            if (sourceOrder.getNotes() != null && !sourceOrder.getNotes().trim().isEmpty()) {
                if (!combinedNotes.isEmpty()) combinedNotes += " | ";
                combinedNotes += "Merged from " + source.getName() + ": " + sourceOrder.getNotes();
            }
            targetOrder.setNotes(combinedNotes);

            // Recalculate billing amount
            int total = 0;
            for (OrderItem item : targetOrder.getItems()) {
                total += item.getPrice() * item.getQuantity();
            }
            targetOrder.setTotalAmount(total);
            targetOrder.setUpdatedAt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));

            // Recalculate status
            recalculateAggregatedOrderStatus(targetOrder);
            orderDAO.update(targetOrder);

            // Remove source order
            sourceOrder.setStatus("Served"); // close source
            orderDAO.update(sourceOrder);
        }

        // Reset Source Table
        source.setStatus("empty");
        source.setActiveOrderId(null);
        tableDAO.update(source);

        // Update Target Table Status
        if (targetOrder != null) {
            if ("Ready".equalsIgnoreCase(targetOrder.getStatus())) {
                target.setStatus("ready_to_serve");
            } else {
                target.setStatus("serving");
            }
        }
        tableDAO.update(target);

        notifyStateChange();
    }

    /**
     * Processes table billing checkout and clears seating states
     */
    public synchronized Order checkoutTable(String tableId) {
        Table table = tableDAO.getById(tableId);
        if (table == null || table.getActiveOrderId() == null) return null;

        String orderId = table.getActiveOrderId();
        Order order = orderDAO.getById(orderId);
        if (order != null) {
            order.setStatus("Served");
            // Set all items as served
            for (OrderItem item : order.getItems()) {
                item.setStatus("Served");
            }
            order.setUpdatedAt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
            orderDAO.update(order);
        }

        // Empty table
        table.setStatus("empty");
        table.setActiveOrderId(null);
        tableDAO.update(table);

        notifyStateChange();
        return order;
    }

    private void notifyStateChange() {
        if (webSocketHandler != null) {
            // Simple robust JSON broadcast payload
            webSocketHandler.broadcast("{\"type\":\"STATE_UPDATED\"}");
        }
    }
}
