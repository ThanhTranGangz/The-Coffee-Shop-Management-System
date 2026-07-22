package service;

import dao.MenuDAO;
import dao.TableDAO;
import dao.OrderDAO;
import model.*;
import websocket.BrewWebSocketHandler;

import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Central state management service for the coffee shop system.
 * Handles business logic, inventory tracking, order management, and real-time updates.
 */
public class BrewStateService {
    public static class RecipeRequirement {
        private String ingredientId;
        private int quantityPerUnit;

        public RecipeRequirement(String ingredientId, int quantityPerUnit) {
            this.ingredientId = ingredientId;
            this.quantityPerUnit = quantityPerUnit;
        }

        public String getIngredientId() { return ingredientId; }
        public int getQuantityPerUnit() { return quantityPerUnit; }
    }

    private final MenuDAO menuDAO;
    private final TableDAO tableDAO;
    private final OrderDAO orderDAO;
    private final dao.StaffDAO staffDAO;

    private final dao.ShiftDAO shiftDAO;
    private final BrewWebSocketHandler webSocketHandler;
    private final AtomicInteger orderCounter = new AtomicInteger(100);
    private boolean shopClosed = false;
    private boolean timeLimitUnlocked = false;
    private final List<Map<String, Object>> paymentEvents = new ArrayList<>();
    private Map<String, Object> currentPosShift = null;
    private int posShiftCounter = 1;

    public synchronized boolean isShopClosed() { return shopClosed; }
    public synchronized void setShopClosed(boolean closed) {
        this.shopClosed = closed;
        notifyStateChange();
    }
    public synchronized boolean isTimeLimitUnlocked() { return timeLimitUnlocked; }
    public synchronized void setTimeLimitUnlocked(boolean unlocked) {
        this.timeLimitUnlocked = unlocked;
        notifyStateChange();
    }

    private final dao.InventoryDAO inventoryDAO;

    private final List<Ingredient> inventory = new ArrayList<>();
    private final List<Expense> expenses = new ArrayList<>();
    private final Map<String, List<RecipeRequirement>> recipes = new HashMap<>();

    /**
     * Constructs the state service with necessary DAOs and handlers.
     * 
     * @param menuDAO data access for menu
     * @param tableDAO data access for tables
     * @param orderDAO data access for orders
     * @param staffDAO data access for staff
     * @param memberDAO data access for members
     * @param inventoryDAO data access for inventory
     * @param shiftDAO data access for shifts
     * @param voucherDAO data access for vouchers
     * @param webSocketHandler the websocket handler
     */
    public BrewStateService(MenuDAO menuDAO, TableDAO tableDAO, OrderDAO orderDAO, dao.StaffDAO staffDAO, dao.InventoryDAO inventoryDAO, dao.ShiftDAO shiftDAO, BrewWebSocketHandler webSocketHandler) {
        this.menuDAO = menuDAO;
        this.tableDAO = tableDAO;
        this.orderDAO = orderDAO;
        this.staffDAO = staffDAO;

        this.inventoryDAO = inventoryDAO;
        this.shiftDAO = shiftDAO;

        this.webSocketHandler = webSocketHandler;
        
        // Initialize Inventory and Recipe models
        initInventoryAndRecipes();

        // Keep runtime counters and old demo data consistent across Tomcat restarts.
        repairStoredOrders();
        syncOrderCounterFromStoredOrders();

        // Seed only once on an empty database so restarts do not create duplicate orders.
        seedInitialOrder();
        repairStoredOrders();
        syncOrderCounterFromStoredOrders();
    }

    private void initInventoryAndRecipes() {
        // Init recipes
        recipes.put("m1", Arrays.asList(new RecipeRequirement("i1", 20)));
        recipes.put("m2", Arrays.asList(new RecipeRequirement("i1", 20), new RecipeRequirement("i2", 30)));
        recipes.put("m3", Arrays.asList(new RecipeRequirement("i1", 20), new RecipeRequirement("i2", 20), new RecipeRequirement("i4", 50)));
        recipes.put("m4", Arrays.asList(new RecipeRequirement("i1", 15), new RecipeRequirement("i3", 100)));
        recipes.put("m5", Arrays.asList(new RecipeRequirement("i5", 30), new RecipeRequirement("i6", 1)));
        recipes.put("m6", Arrays.asList(new RecipeRequirement("i7", 10), new RecipeRequirement("i3", 150)));
        recipes.put("m7", Arrays.asList(new RecipeRequirement("i8", 15), new RecipeRequirement("i3", 100)));
        recipes.put("m8", Arrays.asList(new RecipeRequirement("i9", 1)));
        recipes.put("m9", Arrays.asList(new RecipeRequirement("i10", 1)));

        // Load inventory from our SQL Server Database
        inventory.clear();
        List<Ingredient> dbInventory = inventoryDAO.getAll();
        if (dbInventory != null) {
            inventory.addAll(dbInventory);
        }
    }

    private void seedInitialOrder() {
        try {
            if (!orderDAO.getAll().isEmpty()) {
                return;
            }
            Table table = tableDAO.getById("t3");
            if (table != null && table.getActiveOrderId() == null) {
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

    private void syncOrderCounterFromStoredOrders() {
        int maxOrderNumber = 100;
        for (Order order : orderDAO.getAll()) {
            maxOrderNumber = Math.max(maxOrderNumber, order.getOrderNumber());
        }
        orderCounter.set(maxOrderNumber);
    }

    private void repairStoredOrders() {
        List<Order> orders = new ArrayList<>(orderDAO.getAll());
        if (orders.isEmpty()) {
            return;
        }

        orders.sort(Comparator.comparing(Order::getCreatedAt, Comparator.nullsLast(String::compareTo)));
        Set<Integer> usedNumbers = new HashSet<>();
        int nextNumber = 100;
        for (Order order : orders) {
            nextNumber = Math.max(nextNumber, order.getOrderNumber());
        }

        for (Order order : orders) {
            boolean changed = false;
            int number = order.getOrderNumber();
            if (number <= 0 || usedNumbers.contains(number)) {
                do {
                    nextNumber++;
                } while (usedNumbers.contains(nextNumber));
                order.setOrderNumber(nextNumber);
                changed = true;
            }
            usedNumbers.add(order.getOrderNumber());

            int itemsTotal = calculateItemsTotal(order.getItems());
            if (itemsTotal > 0 && order.getTotalAmount() < 0) {
                order.setTotalAmount(itemsTotal);
                changed = true;
            } else if (itemsTotal > 0 && order.getTotalAmount() == 0 && !looksLikeDiscountedOrder(order)) {
                order.setTotalAmount(itemsTotal);
                changed = true;
            }

            if (changed) {
                orderDAO.update(order);
            }
        }
    }

    private boolean looksLikeDiscountedOrder(Order order) {
        String notes = order.getNotes() == null ? "" : order.getNotes().toLowerCase(Locale.ROOT);
        return notes.contains("voucher") || notes.contains("promo") || notes.contains("discount") || notes.contains("chiết khấu") || notes.contains("khuyến mãi");
    }

    private int calculateItemsTotal(List<OrderItem> items) {
        int total = 0;
        if (items == null) {
            return total;
        }
        for (OrderItem item : items) {
            total += item.getPrice() * item.getQuantity();
        }
        return total;
    }

    public boolean checkIngredientsSufficient(String menuItemId, int quantity) {
        List<RecipeRequirement> recipe = recipes.get(menuItemId);
        if (recipe == null) return true;
        for (RecipeRequirement req : recipe) {
            Ingredient ing = getIngredientById(req.getIngredientId());
            if (ing == null) return false;
            if (ing.getStock() < req.getQuantityPerUnit() * quantity) {
                return false;
            }
        }
        return true;
    }

    private Ingredient getIngredientById(String ingredientId) {
        for (Ingredient ing : inventory) {
            if (ing.getId().equals(ingredientId)) {
                return ing;
            }
        }
        return null;
    }

    public List<Ingredient> getInventory() {
        return inventory;
    }

    public List<Expense> getExpenses() {
        return expenses;
    }

    public synchronized Map<String, Object> importInventory(List<Map<String, Object>> imports) {
        int totalCost = 0;
        List<String> summaryDetails = new ArrayList<>();

        for (Map<String, Object> imp : imports) {
            String id = (String) imp.get("id");
            int quantity = 0;
            if (imp.get("quantity") instanceof Number) {
                quantity = ((Number) imp.get("quantity")).intValue();
            }

            Ingredient ing = getIngredientById(id);
            if (ing != null && quantity > 0) {
                int lineCost = ing.getImportCost() * quantity;
                totalCost += lineCost;
                ing.setStock(ing.getStock() + quantity);
                inventoryDAO.save(ing);
                summaryDetails.add("+" + quantity + " " + ing.getUnit() + " " + ing.getName());
            }
        }

        if (totalCost > 0) {
            String expId = "exp_" + System.currentTimeMillis();
            String timestamp = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX").format(new Date());
            String details = String.join(", ", summaryDetails);
            expenses.add(new Expense(expId, totalCost, details, timestamp));
        }

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Thanh toán và nhập kho thành công!");
        response.put("inventory", inventory);
        response.put("expenses", expenses);
        response.put("totalCost", totalCost);

        notifyStateChange();

        return response;
    }

    public List<MenuItem> getMenu() {
        List<MenuItem> items = menuDAO.getAll();
        for (MenuItem item : items) {
            item.setInStock(checkIngredientsSufficient(item.getId(), 1));
        }
        return items;
    }

    public synchronized MenuItem createMenuItem(String name, String category, int price, String description, List<String> availableSizes, String image) {
        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("Tên món không được để trống.");
        }
        if (price <= 0) {
            throw new IllegalArgumentException("Giá bán phải lớn hơn 0.");
        }

        List<String> sizes = normalizeSizes(availableSizes);
        String cleanCategory = normalizeMenuCategory(category);
        String cleanDescription = description == null || description.trim().isEmpty()
                ? "Món mới được thêm từ trang quản trị."
                : description.trim();
        String cleanImage = image == null ? "" : image.trim();
        String id = "m" + System.currentTimeMillis();

        MenuItem item = new MenuItem(id, name.trim(), cleanCategory, price, cleanDescription, sizes, cleanImage);
        menuDAO.create(item);
        notifyStateChange();
        return item;
    }

    public synchronized MenuItem updateMenuItem(String id, String name, String category, int price, String description, List<String> availableSizes, String image) {
        if (id == null || id.trim().isEmpty()) {
            throw new IllegalArgumentException("Thiếu mã món cần cập nhật.");
        }
        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("Tên món không được để trống.");
        }
        if (price <= 0) {
            throw new IllegalArgumentException("Giá bán phải lớn hơn 0.");
        }

        MenuItem existing = menuDAO.getById(id.trim());
        if (existing == null) {
            throw new IllegalArgumentException("Không tìm thấy món cần cập nhật.");
        }

        existing.setName(name.trim());
        existing.setCategory(normalizeMenuCategory(category));
        existing.setPrice(price);
        existing.setDescription(description == null || description.trim().isEmpty() ? existing.getDescription() : description.trim());
        existing.setAvailableSizes(normalizeSizes(availableSizes));
        existing.setImage(image == null ? "" : image.trim());
        menuDAO.update(existing);
        notifyStateChange();
        return existing;
    }

    public synchronized void deleteMenuItem(String id) {
        if (id == null || id.trim().isEmpty()) {
            throw new IllegalArgumentException("Thiếu mã món cần xoá.");
        }
        menuDAO.delete(id.trim());
        notifyStateChange();
    }

    private List<String> normalizeSizes(List<String> availableSizes) {
        List<String> sizes = new ArrayList<>();
        if (availableSizes != null) {
            for (String size : availableSizes) {
                if (size != null && !size.trim().isEmpty()) {
                    sizes.add(size.trim());
                }
            }
        }
        if (sizes.isEmpty()) {
            sizes.add("S");
            sizes.add("M");
            sizes.add("L");
        }
        return sizes;
    }

    private String normalizeMenuCategory(String category) {
        if (category == null || category.trim().isEmpty()) {
            return "Specialty";
        }
        String clean = category.trim();
        if ("Ice Blended".equalsIgnoreCase(clean) || "Blended".equalsIgnoreCase(clean)) {
            return "Specialty";
        }
        if ("Coffee".equalsIgnoreCase(clean)) return "Coffee";
        if ("Tea".equalsIgnoreCase(clean)) return "Tea";
        if ("Pastry".equalsIgnoreCase(clean)) return "Pastry";
        if ("Specialty".equalsIgnoreCase(clean)) return "Specialty";
        return clean;
    }

    
    
    
    
    public List<Table> getTables() {
        return tableDAO.getAll();
    }

    public Table getTableByCode(String tableCode) {
        return tableDAO.getByCode(tableCode);
    }

    public synchronized Table createTable(String name, String zone, int capacity) {
        String id = "t" + System.currentTimeMillis();
        String status = "empty";
        String tableCode = generateTableCode();
        Table table = new Table(id, name, zone, status, Math.max(1, capacity), null, tableCode);
        tableDAO.create(table);
        notifyStateChange();
        return table;
    }

    private String generateTableCode() {
        String alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        Random random = new Random();
        String code;
        boolean exists;
        do {
            StringBuilder sb = new StringBuilder("TBL-");
            for (int i = 0; i < 6; i++) {
                sb.append(alphabet.charAt(random.nextInt(alphabet.length())));
            }
            code = sb.toString();
            exists = tableDAO.getByCode(code) != null;
        } while (exists);
        return code;
    }

    public List<Order> getOrders() {
        return orderDAO.getAll();
    }

    public Order getOrderByNumber(int orderNumber) {
        for (Order order : orderDAO.getAll()) {
            if (order.getOrderNumber() == orderNumber) {
                return order;
            }
        }
        return null;
    }

    public Order getOrderById(String orderId) {
        if (orderId == null || orderId.trim().isEmpty()) {
            return null;
        }
        return orderDAO.getById(orderId);
    }

    public List<Shift> getShifts() {
        return shiftDAO.getAll();
    }

    public void saveShift(Shift shift) {
        shiftDAO.save(shift);
        notifyStateChange();
    }

    public void deleteShift(String id) {
        shiftDAO.delete(id);
        notifyStateChange();
    }

    public synchronized Map<String, Object> getPosShiftSnapshot() {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("shift", currentPosShift);
        payload.put("events", new ArrayList<>(paymentEvents));
        return payload;
    }

    public synchronized Map<String, Object> openPosShift(String cashierName, int openingCash) {
        if (currentPosShift != null && "OPEN".equals(currentPosShift.get("status"))) {
            return currentPosShift;
        }

        String timestamp = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
        currentPosShift = new LinkedHashMap<>();
        currentPosShift.put("id", "shift-pos-" + (posShiftCounter++));
        currentPosShift.put("status", "OPEN");
        currentPosShift.put("cashierName", cashierName == null || cashierName.trim().isEmpty() ? "Thu ngân" : cashierName.trim());
        currentPosShift.put("openedAt", timestamp);
        currentPosShift.put("closedAt", null);
        currentPosShift.put("openingCash", Math.max(0, openingCash));
        currentPosShift.put("closingCash", 0);
        currentPosShift.put("paidOrders", 0);
        currentPosShift.put("totalRevenue", 0);
        currentPosShift.put("cashTotal", 0);
        currentPosShift.put("bankTotal", 0);
        currentPosShift.put("cardTotal", 0);
        currentPosShift.put("notes", "");
        notifyStateChange();
        return currentPosShift;
    }

    public synchronized Map<String, Object> closePosShift(int closingCash, String notes) {
        if (currentPosShift == null || !"OPEN".equals(currentPosShift.get("status"))) {
            throw new IllegalStateException("Chưa có ca thu ngân nào đang mở.");
        }

        int openingCash = toInt(currentPosShift.get("openingCash"));
        int cashTotal = toInt(currentPosShift.get("cashTotal"));
        int expectedCash = openingCash + cashTotal;
        String timestamp = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());

        currentPosShift.put("status", "CLOSED");
        currentPosShift.put("closedAt", timestamp);
        currentPosShift.put("closingCash", Math.max(0, closingCash));
        currentPosShift.put("expectedCash", expectedCash);
        currentPosShift.put("cashDifference", Math.max(0, closingCash) - expectedCash);
        currentPosShift.put("notes", notes == null ? "" : notes);
        notifyStateChange();
        return currentPosShift;
    }

    public synchronized Map<String, Object> confirmPayment(String orderId, String method, int amount, String reference, String actor) {
        Order order = orderDAO.getById(orderId);
        if (order == null) {
            throw new IllegalArgumentException("Không tìm thấy đơn cần thanh toán.");
        }

        int expectedAmount = order.getTotalAmount();
        int paidAmount = amount <= 0 ? expectedAmount : amount;
        if (paidAmount < expectedAmount) {
            throw new IllegalArgumentException("Số tiền thanh toán thấp hơn tổng hóa đơn.");
        }

        String normalizedMethod = normalizePaymentMethod(method);
        if (!"Served".equalsIgnoreCase(order.getStatus())) {
            Order checkedOrder = order.getTableId() == null ? null : checkoutTable(order.getTableId());
            if (checkedOrder == null) {
                updateOrderStatus(orderId, "Served");
            }
            order = orderDAO.getById(orderId);
            if (order == null) {
                throw new IllegalStateException("Không đọc lại được đơn sau khi chốt thanh toán.");
            }
        }

        Map<String, Object> event = new LinkedHashMap<>();
        event.put("id", "pay-" + UUID.randomUUID().toString().substring(0, 8));
        event.put("orderId", orderId);
        event.put("orderNumber", order.getOrderNumber());
        event.put("tableId", order.getTableId());
        event.put("tableName", order.getTableName());
        event.put("method", normalizedMethod);
        event.put("amount", paidAmount);
        event.put("expectedAmount", expectedAmount);
        event.put("changeAmount", Math.max(0, paidAmount - expectedAmount));
        event.put("reference", reference == null || reference.trim().isEmpty() ? "POS-" + order.getOrderNumber() : reference.trim());
        event.put("actor", actor == null || actor.trim().isEmpty() ? "POS" : actor.trim());
        event.put("status", "SUCCESS");
        event.put("createdAt", new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
        paymentEvents.add(0, event);
        if (paymentEvents.size() > 100) {
            paymentEvents.remove(paymentEvents.size() - 1);
        }

        applyPaymentToCurrentShift(normalizedMethod, expectedAmount);
        notifyStateChange();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("payment", event);
        payload.put("order", order);
        payload.put("shift", currentPosShift);
        return payload;
    }

    public synchronized Map<String, Object> handleBankWebhook(String orderId, int amount, String reference, String bankTrace) {
        if (orderId == null || orderId.trim().isEmpty()) {
            throw new IllegalArgumentException("Webhook ngân hàng thiếu orderId.");
        }
        String webhookRef = reference == null || reference.trim().isEmpty()
                ? "BANK-" + UUID.randomUUID().toString().substring(0, 8)
                : reference.trim();
        if (bankTrace != null && !bankTrace.trim().isEmpty()) {
            webhookRef += " / " + bankTrace.trim();
        }
        return confirmPayment(orderId.trim(), "BANK", amount, webhookRef, "BANK_WEBHOOK");
    }

    public synchronized Map<String, Object> splitBill(String orderId, int parts) {
        Order order = orderDAO.getById(orderId);
        if (order == null) {
            throw new IllegalArgumentException("Không tìm thấy đơn cần tách bill.");
        }
        int validParts = Math.max(1, Math.min(parts, 20));
        int total = order.getTotalAmount();
        int base = total / validParts;
        int remainder = total % validParts;

        List<Map<String, Object>> shares = new ArrayList<>();
        for (int i = 1; i <= validParts; i++) {
            Map<String, Object> share = new LinkedHashMap<>();
            share.put("name", "Khách " + i);
            share.put("amount", base + (i <= remainder ? 1 : 0));
            shares.add(share);
        }

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("orderId", orderId);
        payload.put("orderNumber", order.getOrderNumber());
        payload.put("tableName", order.getTableName());
        payload.put("totalAmount", total);
        payload.put("parts", validParts);
        payload.put("shares", shares);
        return payload;
    }

    private void applyPaymentToCurrentShift(String method, int amount) {
        if (currentPosShift == null || !"OPEN".equals(currentPosShift.get("status"))) {
            openPosShift("Thu ngân tự động", 0);
        }
        currentPosShift.put("paidOrders", toInt(currentPosShift.get("paidOrders")) + 1);
        currentPosShift.put("totalRevenue", toInt(currentPosShift.get("totalRevenue")) + amount);
        if ("CASH".equals(method)) {
            currentPosShift.put("cashTotal", toInt(currentPosShift.get("cashTotal")) + amount);
        } else if ("CARD".equals(method)) {
            currentPosShift.put("cardTotal", toInt(currentPosShift.get("cardTotal")) + amount);
        } else {
            currentPosShift.put("bankTotal", toInt(currentPosShift.get("bankTotal")) + amount);
        }
    }

    private String normalizePaymentMethod(String method) {
        if (method == null) return "CASH";
        String normalized = method.trim().toUpperCase();
        if ("VIETQR".equals(normalized) || "BANK".equals(normalized) || "TRANSFER".equals(normalized)) {
            return "BANK";
        }
        if ("CARD".equals(normalized)) {
            return "CARD";
        }
        return "CASH";
    }

    private int toInt(Object value) {
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        if (value instanceof String) {
            try {
                return Integer.parseInt(((String) value).trim());
            } catch (NumberFormatException ignored) {
                return 0;
            }
        }
        return 0;
    }

    /**
     * Places a new order for a table
     */
    public synchronized Order placeOrder(String tableId, List<Map<String, Object>> rawItems, String notes) {
        return placeOrder(tableId, rawItems, notes, 0);
    }

    public synchronized Order placeOrder(String tableId, List<Map<String, Object>> rawItems, String notes, int discountAmount) {
        Table table = tableDAO.getById(tableId);
        if (table == null) {
            throw new IllegalArgumentException("Table " + tableId + " not found.");
        }

        // 1. Verify if ingredients are sufficient for ALL items in this order
        for (Map<String, Object> rawItem : rawItems) {
            String menuItemId = (String) rawItem.get("menuItemId");
            MenuItem menuItem = menuDAO.getById(menuItemId);
            if (menuItem == null) {
                throw new IllegalArgumentException("Menu item " + menuItemId + " not found.");
            }

            int quantity = 1;
            if (rawItem.get("quantity") instanceof Number) {
                quantity = ((Number) rawItem.get("quantity")).intValue();
            }
            if (quantity <= 0) {
                throw new IllegalArgumentException("Quantity must be greater than zero.");
            }

            if (!checkIngredientsSufficient(menuItemId, quantity)) {
                throw new IllegalStateException("Không đủ nguyên liệu pha chế cho món: " + menuItem.getName() + ". Vui lòng bỏ món này khỏi giỏ hàng!");
            }
        }

        // 2. Perform the deduction of ingredients
        for (Map<String, Object> rawItem : rawItems) {
            String menuItemId = (String) rawItem.get("menuItemId");
            int quantity = 1;
            if (rawItem.get("quantity") instanceof Number) {
                quantity = ((Number) rawItem.get("quantity")).intValue();
            }

            List<RecipeRequirement> recipe = recipes.get(menuItemId);
            if (recipe != null) {
                for (RecipeRequirement req : recipe) {
                    Ingredient ing = getIngredientById(req.getIngredientId());
                    if (ing != null) {
                        ing.setStock(Math.max(0, ing.getStock() - req.getQuantityPerUnit() * quantity));
                        inventoryDAO.save(ing);
                    }
                }
            }
        }

        String orderId = "ord-" + UUID.randomUUID().toString().substring(0, 8);
        String timestamp = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());

        List<OrderItem> orderItems = new ArrayList<>();
        int totalAmount = 0;

        for (Map<String, Object> rawItem : rawItems) {
            String menuItemId = (String) rawItem.get("menuItemId");
            MenuItem menuItem = menuDAO.getById(menuItemId);
            if (menuItem == null) {
                throw new IllegalArgumentException("Menu item " + menuItemId + " not found.");
            }

            int quantity = 1;
            if (rawItem.get("quantity") instanceof Number) {
                quantity = ((Number) rawItem.get("quantity")).intValue();
            }
            if (quantity <= 0) {
                throw new IllegalArgumentException("Quantity must be greater than zero.");
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

        if (orderItems.isEmpty()) {
            throw new IllegalArgumentException("Order must contain at least one valid menu item.");
        }

        if (discountAmount > 0) {
            totalAmount = Math.max(0, totalAmount - discountAmount);
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
        if (order == null) {
            throw new IllegalArgumentException("Không tìm thấy đơn cần cập nhật.");
        }

        boolean itemUpdated = false;
        for (OrderItem item : order.getItems()) {
            if (item.getId().equals(itemId)) {
                String oldStatus = item.getStatus();
                item.setStatus(newStatus);
                itemUpdated = true;
                if ("Preparing".equals(oldStatus) && "Ready".equals(newStatus)) {
                    deductInventoryForItem(item);
                }
                break;
            }
        }

        if (!itemUpdated) {
            throw new IllegalArgumentException("Không tìm thấy món trong đơn cần cập nhật.");
        }

        recalculateAggregatedOrderStatus(order);
        order.setUpdatedAt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
        orderDAO.update(order);
        
        // Update table status sync if needed
        Table table = tableDAO.getById(order.getTableId());
        if (table != null) {
            if ("Ready".equalsIgnoreCase(order.getStatus())) {
                table.setStatus("ready_to_serve");
            } else if ("Served".equalsIgnoreCase(order.getStatus())) {
                table.setStatus("served_confirm");
            }
            tableDAO.update(table);
        }

        notifyStateChange();
    }

    /**
     * Updates entire order status (cascades status to items)
     */
    public synchronized void updateOrderStatus(String orderId, String newStatus) {
        Order order = orderDAO.getById(orderId);
        if (order == null) {
            throw new IllegalArgumentException("Không tìm thấy đơn cần cập nhật.");
        }

        String oldStatus = order.getStatus();
        order.setStatus(newStatus);
        order.setUpdatedAt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));

        // Cascade to children order items
        for (OrderItem item : order.getItems()) {
            String oldItemStatus = item.getStatus();
            item.setStatus(newStatus);
            if ("Preparing".equals(oldItemStatus) && "Ready".equals(newStatus)) {
                deductInventoryForItem(item);
            }
        }
        orderDAO.update(order);

        Table table = tableDAO.getById(order.getTableId());
        if (table != null) {
            if ("Ready".equalsIgnoreCase(newStatus)) {
                table.setStatus("ready_to_serve");
            } else if ("Served".equalsIgnoreCase(newStatus)) {
                table.setStatus("served_confirm");
            } else {
                table.setStatus("serving");
            }
            tableDAO.update(table);
        }

        notifyStateChange();
    }

    private void deductInventoryForItem(OrderItem item) {
        dao.RecipeDAO recipeDao = new dao.RecipeDAO();
        dao.InventoryDAO inventoryDao = new dao.InventoryDAO();
        try {
            java.util.List<model.RecipeItem> recipes = recipeDao.getByMenuItemId(item.getMenuItemId());
            if (recipes != null && !recipes.isEmpty()) {
                for (model.RecipeItem rItem : recipes) {
                    model.Ingredient ing = inventoryDao.getById(rItem.getIngredientId());
                    if (ing != null) {
                        int totalDeduct = rItem.getQuantity() * item.getQuantity();
                        ing.setStock(Math.max(0, ing.getStock() - totalDeduct));
                        inventoryDao.save(ing);
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Error deducting inventory for item: " + e.getMessage());
        }
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

    public synchronized Table confirmTableServed(String tableId) {
        Table table = tableDAO.getById(tableId);
        if (table == null) {
            throw new IllegalArgumentException("Table " + tableId + " not found.");
        }

        if (table.getActiveOrderId() != null) {
            Order order = orderDAO.getById(table.getActiveOrderId());
            if (order != null) {
                order.setStatus("Served");
                for (OrderItem item : order.getItems()) {
                    item.setStatus("Served");
                }
                order.setUpdatedAt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
                orderDAO.update(order);
            }
        }

        table.setStatus("dirty");
        tableDAO.update(table);
        notifyStateChange();
        return table;
    }

    public synchronized Table cleanTable(String tableId) {
        Table table = tableDAO.getById(tableId);
        if (table == null) {
            throw new IllegalArgumentException("Table " + tableId + " not found.");
        }

        if (table.getActiveOrderId() != null) {
            Order order = orderDAO.getById(table.getActiveOrderId());
            if (order != null && !"Served".equalsIgnoreCase(order.getStatus())) {
                order.setStatus("Served");
                for (OrderItem item : order.getItems()) {
                    item.setStatus("Served");
                }
                order.setUpdatedAt(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
                orderDAO.update(order);
            }
        }

        table.setStatus("empty");
        table.setActiveOrderId(null);
        tableDAO.update(table);
        notifyStateChange();
        return table;
    }

    private void notifyStateChange() {
        if (webSocketHandler != null) {
            // Simple robust JSON broadcast payload
            webSocketHandler.broadcast("{\"type\":\"STATE_UPDATED\"}");
        }
    }

    // ==================== STAFF MANAGEMENT METHODS ====================
    public synchronized List<Staff> getStaff() {
        return staffDAO.getAll();
    }

    public synchronized void saveStaff(Staff s) {
        staffDAO.save(s);
        notifyStateChange();
    }

    public synchronized void deleteStaff(int id) {
        staffDAO.delete(id);
        notifyStateChange();
    }

    // ==================== MEMBER LOGIC METHODS ====================
    
    
    
    
    
    
    
    
    
    
    
    
    private String rankForPoints(int points) {
        if (points >= 700) return "Platinum";
        if (points >= 300) return "Gold";
        return "Silver";
    }

    // ==================== HISTORICAL FINANCIAL DATA ====================
    public synchronized List<HistoricalReport> getHistoricalReports() {
        List<HistoricalReport> list = new ArrayList<>();
        
        // 2024 Month-by-month
        list.add(new HistoricalReport(2024, 1, 85000000L, 65000000L, 20000000L, "Profit"));
        list.add(new HistoricalReport(2024, 2, 120000000L, 75000000L, 45000000L, "Profit"));
        list.add(new HistoricalReport(2024, 3, 70000000L, 70000000L, 0L, "Break-even"));
        list.add(new HistoricalReport(2024, 4, 65000000L, 72000000L, -7000000L, "Loss"));
        list.add(new HistoricalReport(2024, 5, 80000000L, 68000000L, 12000000L, "Profit"));
        list.add(new HistoricalReport(2024, 6, 95000000L, 70000000L, 25000000L, "Profit"));
        list.add(new HistoricalReport(2024, 7, 55000000L, 68000000L, -13000000L, "Loss"));
        list.add(new HistoricalReport(2024, 8, 60000000L, 60000000L, 0L, "Break-even"));
        list.add(new HistoricalReport(2024, 9, 75000000L, 65000000L, 10000000L, "Profit"));
        list.add(new HistoricalReport(2024, 10, 82000000L, 66000000L, 16000000L, "Profit"));
        list.add(new HistoricalReport(2024, 11, 90000000L, 67000000L, 23000000L, "Profit"));
        list.add(new HistoricalReport(2024, 12, 110000000L, 70000000L, 40000000L, "Profit"));

        // 2025 Month-by-month
        list.add(new HistoricalReport(2025, 1, 95000000L, 70000000L, 25000000L, "Profit"));
        list.add(new HistoricalReport(2025, 2, 130000000L, 80000000L, 50000000L, "Profit"));
        list.add(new HistoricalReport(2025, 3, 75000000L, 78000000L, -3000050L, "Loss"));
        list.add(new HistoricalReport(2025, 4, 50000000L, 95000000L, -45000000L, "Loss"));
        list.add(new HistoricalReport(2025, 5, 85000000L, 85000000L, 0L, "Break-even"));
        list.add(new HistoricalReport(2025, 6, 100000000L, 75000000L, 25000000L, "Profit"));
        list.add(new HistoricalReport(2025, 7, 72000000L, 72000000L, 0L, "Break-even"));
        list.add(new HistoricalReport(2025, 8, 80000000L, 74000000L, 6000000L, "Profit"));
        list.add(new HistoricalReport(2025, 9, 92000000L, 76000000L, 16000000L, "Profit"));
        list.add(new HistoricalReport(2025, 10, 98000000L, 75000000L, 23000000L, "Profit"));
        list.add(new HistoricalReport(2025, 11, 105000000L, 78000000L, 27000000L, "Profit"));
        list.add(new HistoricalReport(2025, 12, 140000000L, 85000000L, 55000000L, "Profit"));

        return list;
    }
}
