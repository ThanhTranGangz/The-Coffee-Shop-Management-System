package service;

import context.DBContext;

import java.sql.*;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;

public class LiteService {
    private static final LiteService INSTANCE = new LiteService();
    private static final int MAX_ITEM_QUANTITY = 20;
    private static final ZoneId APP_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter SQL_TIMESTAMP_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final DBContext db = new DBContext();

    public static LiteService getInstance() {
        return INSTANCE;
    }

    private LiteService() {
        init();
    }

    private void init() {
        try (Connection con = db.getConnection(); Statement st = con.createStatement()) {
            st.execute("IF OBJECT_ID('dbo.Users','U') IS NULL CREATE TABLE dbo.Users (username VARCHAR(50) PRIMARY KEY, password VARCHAR(100) NOT NULL, role VARCHAR(20) NOT NULL, fullName NVARCHAR(120) NOT NULL)");
            st.execute("IF OBJECT_ID('dbo.Tables','U') IS NULL CREATE TABLE dbo.Tables (id INT IDENTITY PRIMARY KEY, name NVARCHAR(60) NOT NULL, code VARCHAR(40) NULL, active BIT NOT NULL DEFAULT 1)");
            st.execute("IF COL_LENGTH('dbo.Tables','code') IS NULL ALTER TABLE dbo.Tables ADD code VARCHAR(40) NULL");
            st.execute("IF COL_LENGTH('dbo.Tables','floorNo') IS NULL ALTER TABLE dbo.Tables ADD floorNo INT NULL");
            st.execute("IF COL_LENGTH('dbo.Tables','tableNo') IS NULL ALTER TABLE dbo.Tables ADD tableNo INT NULL");
            st.execute("IF OBJECT_ID('dbo.MenuItems','U') IS NULL CREATE TABLE dbo.MenuItems (id INT IDENTITY PRIMARY KEY, nameVi NVARCHAR(120) NOT NULL, nameEn NVARCHAR(120) NOT NULL, category NVARCHAR(60) NOT NULL, price INT NOT NULL, active BIT NOT NULL DEFAULT 1)");
            st.execute("IF COL_LENGTH('dbo.MenuItems','imagePath') IS NULL ALTER TABLE dbo.MenuItems ADD imagePath VARCHAR(255) NULL");
            st.execute("IF OBJECT_ID('dbo.MenuItemSizes','U') IS NULL CREATE TABLE dbo.MenuItemSizes (id INT IDENTITY PRIMARY KEY, menuItemId INT NOT NULL, sizeName NVARCHAR(20) NOT NULL, extraPrice INT NOT NULL DEFAULT 0, sortOrder INT NOT NULL DEFAULT 0, FOREIGN KEY(menuItemId) REFERENCES dbo.MenuItems(id))");
            st.execute("IF OBJECT_ID('dbo.Orders','U') IS NULL CREATE TABLE dbo.Orders (id INT IDENTITY PRIMARY KEY, orderNumber INT NULL UNIQUE, tableName NVARCHAR(60) NOT NULL, customerPhone VARCHAR(20) NULL, status VARCHAR(30) NOT NULL DEFAULT 'Pending', total INT NOT NULL DEFAULT 0, note NVARCHAR(255) NULL, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF COL_LENGTH('dbo.Orders','splitLocked') IS NULL ALTER TABLE dbo.Orders ADD splitLocked BIT NOT NULL DEFAULT 0");
            st.execute("IF COL_LENGTH('dbo.Orders','invoicePrinted') IS NULL ALTER TABLE dbo.Orders ADD invoicePrinted BIT NOT NULL DEFAULT 0");
            st.execute("IF OBJECT_ID('dbo.OrderItems','U') IS NULL CREATE TABLE dbo.OrderItems (id INT IDENTITY PRIMARY KEY, orderId INT NOT NULL, menuItemId INT NOT NULL, itemName NVARCHAR(120) NOT NULL, itemSize VARCHAR(20) NULL, quantity INT NOT NULL, price INT NOT NULL, FOREIGN KEY(orderId) REFERENCES dbo.Orders(id))");
            st.execute("IF COL_LENGTH('dbo.OrderItems','itemSize') IS NULL ALTER TABLE dbo.OrderItems ADD itemSize VARCHAR(20) NULL");
            st.execute("ALTER TABLE dbo.OrderItems ALTER COLUMN itemSize VARCHAR(20) NULL");
            st.execute("IF OBJECT_ID('dbo.CashEvents','U') IS NULL CREATE TABLE dbo.CashEvents (id INT IDENTITY PRIMARY KEY, eventType VARCHAR(30) NOT NULL, amount INT NOT NULL, balanceAfter INT NOT NULL, note NVARCHAR(255) NULL, actorRole VARCHAR(20) NULL, actorName NVARCHAR(120) NULL, seenByCashier BIT NOT NULL DEFAULT 1, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF COL_LENGTH('dbo.CashEvents','seenByCashier') IS NULL ALTER TABLE dbo.CashEvents ADD seenByCashier BIT NOT NULL DEFAULT 1");
            st.execute("IF OBJECT_ID('dbo.StoreState','U') IS NULL CREATE TABLE dbo.StoreState (stateKey VARCHAR(50) PRIMARY KEY, intValue INT NOT NULL, updatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF OBJECT_ID('dbo.SystemLogs','U') IS NULL CREATE TABLE dbo.SystemLogs (id INT IDENTITY PRIMARY KEY, actorRole VARCHAR(20) NOT NULL, actorName NVARCHAR(120) NULL, actionType VARCHAR(40) NOT NULL, messageVi NVARCHAR(400) NOT NULL, messageEn NVARCHAR(400) NOT NULL, refId INT NULL, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF OBJECT_ID('dbo.Staff','U') IS NULL CREATE TABLE dbo.Staff (id INT PRIMARY KEY, name NVARCHAR(120) NOT NULL, role VARCHAR(20) NOT NULL, pin VARCHAR(20) NULL, shift NVARCHAR(100) NULL, active BIT NOT NULL DEFAULT 1, username VARCHAR(50) NULL, password VARCHAR(100) NULL, status VARCHAR(30) NOT NULL DEFAULT 'Active', overtime BIT NOT NULL DEFAULT 0)");
            st.execute("IF OBJECT_ID('dbo.Shifts','U') IS NULL CREATE TABLE dbo.Shifts (id VARCHAR(50) PRIMARY KEY, staffId INT NOT NULL, staffName NVARCHAR(120) NOT NULL, shiftDate VARCHAR(20) NOT NULL, shiftName NVARCHAR(50) NOT NULL, hours VARCHAR(50) NOT NULL, status NVARCHAR(30) NOT NULL, notes NVARCHAR(255) NULL)");
            seed(con);
        } catch (Exception e) {
            System.err.println("LiteService init failed: " + e.getMessage());
        }
    }

    private void seed(Connection con) throws Exception {
        upsertUser(con, "admin", "8888", "admin", "Quản trị coffeshop");
        upsertUser(con, "barista", "1111", "barista", "Pha chế coffeshop");
        upsertUser(con, "cashier", "2222", "cashier", "Thu ngân coffeshop");
        upsertUser(con, "runner", "3333", "runner", "Bồi bàn coffeshop");
        ensureStandardTables(con);
        removeLegacyTables(con);
        clearOrphanActiveOrders(con);
        ensureTableCodes(con);
        seedMenu(con);
        ensureInventoryAndRecipes(con);
        seedSalesHistory(con);
        ensureState(con, "cupsAvailable", 120);
        try (Statement st = con.createStatement()) {
            st.execute("UPDATE dbo.Users SET role='admin', fullName=N'Quản trị coffeshop' WHERE username='admin'");
            st.execute("UPDATE dbo.Users SET password='1111', role='barista', fullName=N'Pha chế coffeshop' WHERE username='staff'");
        }
    }

    private void ensureStandardTables(Connection con) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Tables SET active=0 WHERE floorNo IS NULL OR tableNo IS NULL")) {
            ps.executeUpdate();
        }
        for (int floor = 1; floor <= 2; floor++) {
            for (int table = 1; table <= 6; table++) {
                String name = "Tầng " + floor + " - Bàn " + table;
                try (PreparedStatement ps = con.prepareStatement("IF EXISTS (SELECT 1 FROM dbo.Tables WHERE floorNo=? AND tableNo=?) UPDATE dbo.Tables SET name=? WHERE floorNo=? AND tableNo=? ELSE INSERT INTO dbo.Tables (name, active, floorNo, tableNo) VALUES (?,1,?,?)")) {
                    ps.setInt(1, floor);
                    ps.setInt(2, table);
                    ps.setString(3, name);
                    ps.setInt(4, floor);
                    ps.setInt(5, table);
                    ps.setString(6, name);
                    ps.setInt(7, floor);
                    ps.setInt(8, table);
                    ps.executeUpdate();
                }
            }
        }
    }

    private void removeLegacyTables(Connection con) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM dbo.Tables WHERE floorNo IS NULL OR tableNo IS NULL")) {
            ps.executeUpdate();
        }
    }

    private void clearOrphanActiveOrders(Connection con) throws Exception {
        String sql = "UPDATE dbo.Orders SET status='Cleared' "
                + "WHERE status IN ('Pending','Preparing','Ready','Served','Paid') "
                + "AND NOT EXISTS (SELECT 1 FROM dbo.Tables t WHERE t.active=1 AND t.floorNo IS NOT NULL AND t.name=dbo.Orders.tableName)";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.executeUpdate();
        }
    }

    private void seedMenu(Connection con) throws Exception {
        upsertMenuItem(con, "Cà phê sữa", "Milk Coffee", "Cà phê", 30000, "assets/img/menu/coffee.jpg");
        upsertMenuItem(con, "Cà phê đen", "Black Coffee", "Cà phê", 28000, "assets/img/menu/coffee.jpg");
        upsertMenuItem(con, "Bạc xỉu", "White Coffee", "Cà phê", 32000, "assets/img/menu/latte.jpg");
        upsertMenuItem(con, "Espresso", "Espresso", "Cà phê", 30000, "assets/img/menu/coffee.jpg");
        upsertMenuItem(con, "Cappuccino", "Cappuccino", "Cà phê", 38000, "assets/img/menu/latte.jpg");
        upsertMenuItem(con, "Latte", "Latte", "Cà phê", 40000, "assets/img/menu/latte.jpg");
        upsertMenuItem(con, "Trà đào", "Peach Tea", "Trà", 35000, "assets/img/menu/tea.jpg");
        upsertMenuItem(con, "Trà vải", "Lychee Tea", "Trà", 36000, "assets/img/menu/tea.jpg");
        upsertMenuItem(con, "Trà sen vàng", "Lotus Tea", "Trà", 39000, "assets/img/menu/tea.jpg");
        upsertMenuItem(con, "Matcha latte", "Matcha Latte", "Đặc biệt", 42000, "assets/img/menu/matcha.jpg");
        upsertMenuItem(con, "Socola đá", "Iced Chocolate", "Đặc biệt", 40000, "assets/img/menu/matcha.jpg");
        upsertMenuItem(con, "Sinh tố xoài", "Mango Smoothie", "Đặc biệt", 45000, "assets/img/menu/smoothie.jpg");
        upsertMenuItem(con, "Bánh croissant", "Croissant", "Bánh ngọt", 28000, "assets/img/menu/pastry.jpg");
        upsertMenuItem(con, "Tiramisu", "Tiramisu", "Bánh ngọt", 42000, "assets/img/menu/pastry.jpg");
        upsertMenuItem(con, "Cheesecake", "Cheesecake", "Bánh ngọt", 45000, "assets/img/menu/pastry.jpg");
    }

    private void ensureInventoryAndRecipes(Connection con) throws Exception {
        try (Statement st = con.createStatement()) {
            st.execute("IF OBJECT_ID('dbo.Inventory','U') IS NULL CREATE TABLE dbo.Inventory (id VARCHAR(50) PRIMARY KEY, name NVARCHAR(120) NOT NULL, unit NVARCHAR(20) NOT NULL, stock INT NOT NULL DEFAULT 0, minStock INT NOT NULL DEFAULT 0, importCost INT NOT NULL DEFAULT 0)");
            st.execute("IF OBJECT_ID('dbo.RecipeItems','U') IS NULL CREATE TABLE dbo.RecipeItems (id VARCHAR(50) PRIMARY KEY, menuItemId VARCHAR(50) NOT NULL, ingredientId VARCHAR(50) NOT NULL, quantity INT NOT NULL)");
            st.execute("DELETE FROM dbo.RecipeItems WHERE menuItemId LIKE 'm%'");
        }
        insertIngredientIfMissing(con, "i1", "Hạt cà phê nguyên chất", "g", 1500, 300, 50);
        insertIngredientIfMissing(con, "i2", "Sữa đặc", "g", 1000, 200, 40);
        insertIngredientIfMissing(con, "i3", "Sữa tươi", "ml", 2000, 500, 20);
        insertIngredientIfMissing(con, "i4", "Kem muối", "ml", 600, 150, 80);
        insertIngredientIfMissing(con, "i5", "Siro đào", "ml", 600, 100, 60);
        insertIngredientIfMissing(con, "i6", "Sả tươi", "nhánh", 20, 5, 1000);
        insertIngredientIfMissing(con, "i7", "Bột matcha", "g", 500, 100, 200);
        insertIngredientIfMissing(con, "i8", "Lá trà ô long", "g", 500, 100, 100);
        insertIngredientIfMissing(con, "i9", "Vỏ croissant", "cái", 15, 4, 15000);
        insertIngredientIfMissing(con, "i10", "Bánh tiramisu", "lát", 15, 3, 25000);
        insertIngredientIfMissing(con, "i11", "Bột cacao", "g", 800, 150, 120);
        insertIngredientIfMissing(con, "i12", "Sinh tố xoài", "ml", 1200, 250, 80);
        insertIngredientIfMissing(con, "i13", "Siro vải", "ml", 800, 150, 60);
        insertIngredientIfMissing(con, "i14", "Nền trà sen", "ml", 800, 150, 70);
        insertIngredientIfMissing(con, "i15", "Bánh cheesecake", "lát", 15, 3, 28000);
        seedMissingRecipes(con);
    }

    private void insertIngredientIfMissing(Connection con, String id, String name, String unit, int stock, int minStock, int importCost) throws Exception {
        String sql = "IF NOT EXISTS (SELECT 1 FROM dbo.Inventory WHERE id=?) "
                + "INSERT INTO dbo.Inventory (id,name,unit,stock,minStock,importCost) VALUES (?,?,?,?,?,?)";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.setString(2, id);
            ps.setString(3, name);
            ps.setString(4, unit);
            ps.setInt(5, stock);
            ps.setInt(6, minStock);
            ps.setInt(7, importCost);
            ps.executeUpdate();
        }
    }

    private void seedMissingRecipes(Connection con) throws Exception {
        List<Map<String, Object>> menu = queryRows(con, "SELECT id, nameVi, category FROM dbo.MenuItems WHERE active=1");
        for (Map<String, Object> item : menu) {
            int menuId = readInt(item.get("id"), 0);
            if (menuId <= 0 || recipeLineCount(con, menuId) > 0) continue;
            List<Map<String, Object>> defaults = defaultRecipeRows(readString(item.get("nameVi"), ""), readString(item.get("category"), ""));
            if (defaults.isEmpty()) continue;
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.RecipeItems (id,menuItemId,ingredientId,quantity) VALUES (?,?,?,?)")) {
                for (Map<String, Object> row : defaults) {
                    String ingredientId = readString(row.get("ingredientId"), "");
                    int quantity = readInt(row.get("quantity"), 0);
                    if (ingredientId.isEmpty() || quantity <= 0) continue;
                    ps.setString(1, "AUTO-" + menuId + "-" + ingredientId);
                    ps.setString(2, String.valueOf(menuId));
                    ps.setString(3, ingredientId);
                    ps.setInt(4, quantity);
                    ps.addBatch();
                }
                ps.executeBatch();
            }
        }
    }

    private int recipeLineCount(Connection con, int menuId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.RecipeItems WHERE menuItemId=?")) {
            ps.setString(1, String.valueOf(menuId));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private List<Map<String, Object>> defaultRecipeRows(String nameVi, String category) {
        String name = fold(nameVi);
        List<Map<String, Object>> rows = new ArrayList<>();
        if (name.contains("bac xiu")) return recipeRows(recipe("i1", 20), recipe("i2", 20), recipe("i4", 50));
        if (name.contains("ca phe sua")) return recipeRows(recipe("i1", 20), recipe("i2", 30));
        if (name.contains("ca phe den") || name.contains("espresso")) return recipeRows(recipe("i1", 20));
        if (name.contains("cappuccino") || (name.contains("latte") && !name.contains("matcha"))) return recipeRows(recipe("i1", 18), recipe("i3", 120));
        if (name.contains("matcha")) return recipeRows(recipe("i7", 10), recipe("i3", 150));
        if (name.contains("socola") || name.contains("chocolate")) return recipeRows(recipe("i11", 20), recipe("i3", 150));
        if (name.contains("xoai") || name.contains("mango")) return recipeRows(recipe("i12", 150));
        if (name.contains("tra dao")) return recipeRows(recipe("i5", 30), recipe("i6", 1));
        if (name.contains("tra vai")) return recipeRows(recipe("i13", 30), recipe("i8", 12));
        if (name.contains("tra sen")) return recipeRows(recipe("i14", 30), recipe("i8", 12));
        if (name.contains("tra sua")) return recipeRows(recipe("i8", 15), recipe("i3", 100));
        if (name.contains("croissant")) return recipeRows(recipe("i9", 1));
        if (name.contains("tiramisu")) return recipeRows(recipe("i10", 1));
        if (name.contains("cheesecake")) return recipeRows(recipe("i15", 1));
        if (isDrinkCategory(category)) rows.add(recipe("i3", 100));
        return rows;
    }

    @SafeVarargs
    private final List<Map<String, Object>> recipeRows(Map<String, Object>... rows) {
        return new ArrayList<>(Arrays.asList(rows));
    }

    private Map<String, Object> recipe(String ingredientId, int quantity) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("ingredientId", ingredientId);
        row.put("quantity", quantity);
        return row;
    }

    private void upsertMenuItem(Connection con, String nameVi, String nameEn, String category, int price, String imagePath) throws Exception {
        int id = 0;
        try (PreparedStatement ps = con.prepareStatement("MERGE dbo.MenuItems AS t USING (SELECT ? nameVi, ? nameEn, ? category, ? price, ? imagePath) AS s ON t.nameVi=s.nameVi WHEN MATCHED THEN UPDATE SET nameEn=s.nameEn, category=s.category, price=s.price, imagePath=s.imagePath, active=1 WHEN NOT MATCHED THEN INSERT(nameVi,nameEn,category,price,imagePath,active) VALUES(s.nameVi,s.nameEn,s.category,s.price,s.imagePath,1);")) {
            ps.setString(1, nameVi);
            ps.setString(2, nameEn);
            ps.setString(3, category);
            ps.setInt(4, price);
            ps.setString(5, imagePath);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = con.prepareStatement("SELECT id FROM dbo.MenuItems WHERE nameVi=?")) {
            ps.setString(1, nameVi);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) id = rs.getInt("id");
            }
        }
        if (id > 0 && isDrinkCategory(category) && count(con, "SELECT COUNT(*) FROM dbo.MenuItemSizes WHERE menuItemId=" + id) == 0) {
            saveMenuSizes(con, id, Arrays.asList(sizeRow("S", 0), sizeRow("M", 5000), sizeRow("L", 10000)));
        }
    }

    private Map<String, Object> sizeRow(String name, int extraPrice) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("sizeName", name);
        row.put("extraPrice", extraPrice);
        return row;
    }

    private void seedSalesHistory(Connection con) throws Exception {
        LocalDate today = appToday();
        boolean enoughHistory = countSince(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status='Cleared' AND createdAt >= ?", today.minusDays(370)) >= 160;

        List<Map<String, Object>> menu = queryRows(con, "SELECT id, nameVi, category, price FROM dbo.MenuItems WHERE active=1 ORDER BY id");
        for (Map<String, Object> item : menu) {
            item.put("sizes", getMenuSizes(con, readInt(item.get("id"), 0)));
        }
        List<Map<String, Object>> tables = queryRows(con, "SELECT name FROM dbo.Tables WHERE active=1 AND floorNo IS NOT NULL ORDER BY floorNo, tableNo");
        if (menu.isEmpty() || tables.isEmpty()) return;

        Random random = new Random(205063);
        if (!enoughHistory) {
            LocalDate start = today.minusDays(360);
            for (int day = 0; day <= 360; day += 3) {
                int orders = 2 + random.nextInt(4);
                LocalDate date = start.plusDays(day);
                for (int i = 0; i < orders; i++) {
                    String tableName = readString(tables.get(random.nextInt(tables.size())).get("name"), "Tầng 1 - Bàn 1");
                    String createdAt = date + "T" + String.format(Locale.ROOT, "%02d:%02d:00", 8 + random.nextInt(13), random.nextInt(60));
                    int orderId = insertSeedOrder(con, tableName, createdAt, "Cleared");
                    int lineCount = 1 + random.nextInt(3);
                    int total = 0;
                    Set<Integer> used = new HashSet<>();
                    for (int line = 0; line < lineCount; line++) {
                        Map<String, Object> item = menu.get(random.nextInt(menu.size()));
                        int menuId = readInt(item.get("id"), 0);
                        if (!used.add(menuId) && menu.size() > lineCount) continue;
                        int quantity = 1 + random.nextInt(2);
                        String size = isDrink(item) ? Arrays.asList("S", "M", "L").get(random.nextInt(3)) : "";
                        int price = priceForSize(item, size);
                        total += price * quantity;
                        insertSeedOrderItem(con, orderId, menuId, readString(item.get("nameVi"), ""), size, quantity, price);
                    }
                    finishSeedOrder(con, orderId, total);
                }
            }
        }

        if (count(con, "SELECT COUNT(*) FROM dbo.Orders o JOIN dbo.Tables t ON t.name=o.tableName WHERE o.status IN ('Pending','Preparing','Ready','Served','Paid') AND t.active=1 AND t.floorNo IS NOT NULL") == 0) {
            insertLiveOrder(con, "Tầng 1 - Bàn 1", menu, "Pending", random);
            insertLiveOrder(con, "Tầng 1 - Bàn 2", menu, "Ready", random);
            insertLiveOrder(con, "Tầng 2 - Bàn 1", menu, "Served", random);
            insertLiveOrder(con, "Tầng 2 - Bàn 2", menu, "Paid", random);
        }
    }

    private int insertSeedOrder(Connection con, String tableName, String createdAt, String status) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.Orders (tableName, status, total, createdAt) VALUES (?,?,0,?)", Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, tableName);
            ps.setString(2, status);
            ps.setString(3, createdAt);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    private void insertSeedOrderItem(Connection con, int orderId, int menuId, String itemName, String size, int quantity, int price) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.OrderItems (orderId,menuItemId,itemName,itemSize,quantity,price) VALUES (?,?,?,?,?,?)")) {
            ps.setInt(1, orderId);
            ps.setInt(2, menuId);
            ps.setString(3, itemName);
            ps.setString(4, size == null || size.isEmpty() ? null : size);
            ps.setInt(5, quantity);
            ps.setInt(6, price);
            ps.executeUpdate();
        }
    }

    private void finishSeedOrder(Connection con, int orderId, int total) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET orderNumber=?, total=? WHERE id=?")) {
            ps.setInt(1, 1000 + orderId);
            ps.setInt(2, total);
            ps.setInt(3, orderId);
            ps.executeUpdate();
        }
    }

    private void insertLiveOrder(Connection con, String tableName, List<Map<String, Object>> menu, String status, Random random) throws Exception {
        int orderId = insertSeedOrder(con, tableName, appToday() + "T" + String.format(Locale.ROOT, "%02d:%02d:00", 9 + random.nextInt(8), random.nextInt(60)), status);
        Map<String, Object> item = menu.get(random.nextInt(menu.size()));
        String size = isDrink(item) ? "M" : "";
        int price = priceForSize(item, size);
        insertSeedOrderItem(con, orderId, readInt(item.get("id"), 0), readString(item.get("nameVi"), ""), size, 1, price);
        finishSeedOrder(con, orderId, price);
    }

    private int count(Connection con, String sql) throws Exception {
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getInt(1);
        }
    }

    private int countSince(Connection con, String sql, LocalDate start) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private void upsertUser(Connection con, String username, String password, String role, String fullName) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("MERGE dbo.Users AS t USING (SELECT ? username, ? password, ? role, ? fullName) AS s ON t.username=s.username WHEN MATCHED THEN UPDATE SET password=s.password, role=s.role, fullName=s.fullName WHEN NOT MATCHED THEN INSERT(username,password,role,fullName) VALUES(s.username,s.password,s.role,s.fullName);")) {
            ps.setString(1, username);
            ps.setString(2, password);
            ps.setString(3, role);
            ps.setString(4, fullName);
            ps.executeUpdate();
        }
    }

    private void executeIfEmpty(Connection con, String table, String sql) throws Exception {
        try (Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM " + table)) {
            rs.next();
            if (rs.getInt(1) == 0) {
                st.execute(sql);
            }
        }
    }

    private void ensureState(Connection con, String key, int value) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("IF NOT EXISTS (SELECT 1 FROM dbo.StoreState WHERE stateKey=?) INSERT INTO dbo.StoreState (stateKey,intValue) VALUES (?,?)")) {
            ps.setString(1, key);
            ps.setString(2, key);
            ps.setInt(3, value);
            ps.executeUpdate();
        }
    }

    private void ensureTableCodes(Connection con) throws Exception {
        List<Integer> missing = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement("SELECT id FROM dbo.Tables WHERE code IS NULL OR LTRIM(RTRIM(code))=''");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) missing.add(rs.getInt("id"));
        }
        for (Integer id : missing) {
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Tables SET code=? WHERE id=?")) {
                ps.setString(1, uniqueTableCode(con));
                ps.setInt(2, id);
                ps.executeUpdate();
            }
        }
    }

    private String uniqueTableCode(Connection con) throws Exception {
        for (int i = 0; i < 20; i++) {
            String code = "TB-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase(Locale.ROOT);
            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.Tables WHERE code=?")) {
                ps.setString(1, code);
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) == 0) return code;
                }
            }
        }
        throw new IllegalStateException("Không tạo được mã QR cho bàn.");
    }

    public Map<String, Object> login(String username, String password) throws Exception {
        String sql = "SELECT username, role, fullName FROM dbo.Users WHERE username=? AND password=?";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    public List<Map<String, Object>> getMenu(boolean includeInactive) throws Exception {
        String sql = "SELECT id, nameVi, nameEn, category, price, active, imagePath FROM dbo.MenuItems " + (includeInactive ? "" : "WHERE active=1 ") + "ORDER BY category, nameVi";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            List<Map<String, Object>> menu = rows(rs);
            Set<Integer> bestSellerIds = getBestSellerMenuIdsByCategory(con, menu);
            
            dao.RecipeDAO recipeDao = new dao.RecipeDAO();
            java.util.Map<String, java.util.List<model.RecipeItem>> allRecipes = recipeDao.getAllRecipesMappedByMenuItemId();
            java.util.Map<Integer, java.util.List<Map<String, Object>>> allSizes = getAllMenuSizesMapped(con);
            Map<String, Integer> stockMap = getIngredientStockMap(con);
            Map<Integer, Integer> reservedMap = getReservedMenuQuantityMap(con);
            
            List<Map<String, Object>> visible = new ArrayList<>();
            for (Map<String, Object> item : menu) {
                int itemId = readInt(item.get("id"), 0);
                List<model.RecipeItem> recipes = allRecipes.getOrDefault(String.valueOf(itemId), new java.util.ArrayList<>());
                int availableQty = availableQuantity(recipes, stockMap, reservedMap.getOrDefault(itemId, 0));
                item.put("sizes", allSizes.getOrDefault(itemId, new java.util.ArrayList<>()));
                item.put("recipes", recipes.stream().map(r -> r.toMap()).collect(java.util.stream.Collectors.toList()));
                item.put("bestSeller", bestSellerIds.contains(itemId));
                item.put("availableQty", availableQty);
                if (includeInactive || recipes.isEmpty() || availableQty > 0) {
                    visible.add(item);
                }
            }
            return visible;
        }
    }

    private Set<Integer> getBestSellerMenuIdsByCategory(Connection con, List<Map<String, Object>> menu) throws Exception {
        Set<Integer> ids = new LinkedHashSet<>();
        Set<Integer> menuIds = new HashSet<>();
        for (Map<String, Object> item : menu) {
            int itemId = readInt(item.get("id"), 0);
            if (itemId > 0) menuIds.add(itemId);
        }
        if (menuIds.isEmpty()) return ids;
        Set<String> claimedCategories = new HashSet<>();
        String sql = "SELECT m.category, oi.menuItemId, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue "
                + "FROM dbo.OrderItems oi "
                + "JOIN dbo.Orders o ON o.id = oi.orderId "
                + "JOIN dbo.MenuItems m ON m.id = oi.menuItemId "
                + "WHERE o.status IN ('Paid','Cleared') AND oi.menuItemId IS NOT NULL AND oi.menuItemId > 0 "
                + "GROUP BY m.category, oi.menuItemId "
                + "ORDER BY m.category, SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC, oi.menuItemId";
        try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String category = readString(rs.getString("category"), "");
                int menuItemId = rs.getInt("menuItemId");
                if (category.isEmpty() || menuItemId <= 0 || !menuIds.contains(menuItemId) || !claimedCategories.add(category)) continue;
                ids.add(menuItemId);
            }
        }
        return ids;
    }

    public Map<String, Object> saveMenuItem(Map<String, Object> data) throws Exception {
        int id = readInt(data.get("id"), 0);
        String nameVi = readString(data.get("nameVi"), "");
        String nameEn = readString(data.get("nameEn"), nameVi);
        String category = normalizeCategory(readString(data.get("category"), "Cà phê"));
        int price = readInt(data.get("price"), 0);
        boolean active = readBoolean(data.get("active"), true);
        String imagePath = readString(data.get("imagePath"), defaultImagePath(category));
        boolean hasSizes = readBoolean(data.get("hasSizes"), false);
        List<Map<String, Object>> sizes = normalizeSizeRows(data.get("sizes"), hasSizes);
        validateMenuItem(id, nameVi, nameEn, category, price, imagePath);

        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            if (menuNameExists(con, id, nameVi, nameEn)) {
                throw new IllegalArgumentException("Tên món đã tồn tại.");
            }
            if (id > 0) {
                try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.MenuItems SET nameVi=?, nameEn=?, category=?, price=?, active=?, imagePath=? WHERE id=?")) {
                    ps.setString(1, nameVi);
                    ps.setString(2, nameEn);
                    ps.setString(3, category);
                    ps.setInt(4, price);
                    ps.setBoolean(5, active);
                    ps.setString(6, imagePath);
                    ps.setInt(7, id);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.MenuItems (nameVi,nameEn,category,price,active,imagePath) VALUES (?,?,?,?,?,?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, nameVi);
                    ps.setString(2, nameEn);
                    ps.setString(3, category);
                    ps.setInt(4, price);
                    ps.setBoolean(5, active);
                    ps.setString(6, imagePath);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (keys.next()) id = keys.getInt(1);
                    }
                }
            }
            saveMenuSizes(con, id, sizes);
            saveMenuRecipes(id, data.get("recipes"));
            con.commit();
        }
        return getMenuItem(id);
    }

    private void saveMenuRecipes(int menuItemId, Object recipesObj) {
        if (recipesObj instanceof List) {
            List<Map<String, Object>> list = (List<Map<String, Object>>) recipesObj;
            List<model.RecipeItem> recipeItems = new java.util.ArrayList<>();
            for (Map<String, Object> row : list) {
                String ingredientId = readString(row.get("ingredientId"), "");
                int quantity = readInt(row.get("quantity"), 0);
                if (!ingredientId.isEmpty() && quantity > 0) {
                    model.RecipeItem item = new model.RecipeItem();
                    item.setIngredientId(ingredientId);
                    item.setQuantity(quantity);
                    recipeItems.add(item);
                }
            }
            new dao.RecipeDAO().saveForMenuItem(String.valueOf(menuItemId), recipeItems);
        }
    }

    public void deleteMenuItem(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("UPDATE dbo.MenuItems SET active=0 WHERE id=?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    public Map<String, Object> getMenuItem(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, nameVi, nameEn, category, price, active, imagePath FROM dbo.MenuItems WHERE id=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String, Object> item = row(rs);
                item.put("sizes", getMenuSizes(con, id));
                item.put("recipes", new dao.RecipeDAO().getByMenuItemId(String.valueOf(id)).stream().map(r -> r.toMap()).collect(java.util.stream.Collectors.toList()));
                return item;
            }
        }
    }

    public Map<String, Object> importMenuItems(List<Map<String, Object>> rows) {
        List<Map<String, Object>> imported = new ArrayList<>();
        List<Map<String, Object>> skipped = new ArrayList<>();
        int rowNumber = 1;
        for (Map<String, Object> data : rows) {
            rowNumber++;
            try {
                imported.add(saveMenuItem(data));
            } catch (Exception e) {
                Map<String, Object> failure = new LinkedHashMap<>();
                failure.put("row", rowNumber);
                failure.put("nameVi", readString(data.get("nameVi"), ""));
                failure.put("reason", e.getMessage());
                skipped.add(failure);
            }
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("importedCount", imported.size());
        result.put("skippedCount", skipped.size());
        result.put("imported", imported);
        result.put("skipped", skipped);
        return result;
    }

    private void validateMenuItem(int id, String nameVi, String nameEn, String category, int price, String imagePath) {
        if (nameVi.length() < 2 || nameVi.length() > 80) {
            throw new IllegalArgumentException("Tên tiếng Việt phải từ 2 đến 80 ký tự.");
        }
        if (nameEn.length() < 2 || nameEn.length() > 80) {
            throw new IllegalArgumentException("Tên tiếng Anh phải từ 2 đến 80 ký tự.");
        }
        if (!allowedCategories().contains(category)) {
            throw new IllegalArgumentException("Nhóm món không hợp lệ.");
        }
        if (price < 10000 || price > 200000 || price % 1000 != 0) {
            throw new IllegalArgumentException("Giá phải từ 10.000đ đến 200.000đ và chia hết cho 1.000đ.");
        }
        if (!imagePath.startsWith("assets/img/menu/") || !(imagePath.endsWith(".jpg") || imagePath.endsWith(".png"))) {
            throw new IllegalArgumentException("Ảnh món phải là ảnh thật JPG/PNG trong thư mục assets/img/menu.");
        }
    }

    private boolean menuNameExists(Connection con, int id, String nameVi, String nameEn) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.MenuItems WHERE id<>? AND (LOWER(nameVi)=LOWER(?) OR LOWER(nameEn)=LOWER(?))")) {
            ps.setInt(1, id);
            ps.setString(2, nameVi);
            ps.setString(3, nameEn);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    private List<Map<String, Object>> getMenuSizes(Connection con, int menuItemId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT sizeName, extraPrice FROM dbo.MenuItemSizes WHERE menuItemId=? ORDER BY sortOrder, id")) {
            ps.setInt(1, menuItemId);
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    private java.util.Map<Integer, java.util.List<Map<String, Object>>> getAllMenuSizesMapped(Connection con) throws Exception {
        java.util.Map<Integer, java.util.List<Map<String, Object>>> map = new java.util.HashMap<>();
        try (PreparedStatement ps = con.prepareStatement("SELECT menuItemId, sizeName, extraPrice FROM dbo.MenuItemSizes ORDER BY sortOrder, id");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int menuId = rs.getInt("menuItemId");
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("sizeName", rs.getString("sizeName"));
                row.put("extraPrice", rs.getInt("extraPrice"));
                map.computeIfAbsent(menuId, k -> new java.util.ArrayList<>()).add(row);
            }
        }
        return map;
    }

    private void saveMenuSizes(Connection con, int menuItemId, List<Map<String, Object>> sizes) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM dbo.MenuItemSizes WHERE menuItemId=?")) {
            ps.setInt(1, menuItemId);
            ps.executeUpdate();
        }
        int index = 0;
        try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.MenuItemSizes (menuItemId,sizeName,extraPrice,sortOrder) VALUES (?,?,?,?)")) {
            for (Map<String, Object> size : sizes) {
                ps.setInt(1, menuItemId);
                ps.setString(2, readString(size.get("sizeName"), "S"));
                ps.setInt(3, readInt(size.get("extraPrice"), 0));
                ps.setInt(4, index++);
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private List<Map<String, Object>> normalizeSizeRows(Object raw, boolean hasSizes) {
        if (!hasSizes) return new ArrayList<>();
        List<Map<String, Object>> normalized = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        normalized.add(sizeRow("S", 0));
        seen.add("S");
        if (raw instanceof List<?>) {
            for (Object entry : (List<?>) raw) {
                if (!(entry instanceof Map<?, ?>)) continue;
                Map<?, ?> row = (Map<?, ?>) entry;
                String name = readString(row.get("sizeName"), "").trim().toUpperCase(Locale.ROOT);
                if (name.isEmpty() || name.length() > 12 || !name.matches("[A-Z0-9+\\- ]+")) {
                    throw new IllegalArgumentException("Tên size chỉ dùng chữ, số, dấu + hoặc - và tối đa 12 ký tự.");
                }
                int extra = readInt(row.get("extraPrice"), 0);
                if (extra < 0 || extra > 100000 || extra % 1000 != 0) {
                    throw new IllegalArgumentException("Tiền chênh size phải từ 0đ đến 100.000đ và chia hết cho 1.000đ.");
                }
                if ("S".equals(name)) {
                    if (extra != 0) throw new IllegalArgumentException("Size S là giá gốc nên tiền chênh phải bằng 0.");
                    continue;
                }
                if (seen.add(name)) normalized.add(sizeRow(name, extra));
            }
        }
        if (normalized.size() > 8) throw new IllegalArgumentException("Một sản phẩm chỉ nên có tối đa 8 size.");
        return normalized;
    }

    private List<String> allowedCategories() {
        return Arrays.asList("Cà phê", "Trà", "Đặc biệt", "Bánh ngọt");
    }

    private String normalizeCategory(String category) {
        String folded = fold(category);
        if (folded.contains("coffee") || folded.contains("ca phe")) return "Cà phê";
        if (folded.contains("tea") || folded.contains("tra")) return "Trà";
        if (folded.contains("special") || folded.contains("dac biet")) return "Đặc biệt";
        if (folded.contains("food") || folded.contains("pastry") || folded.contains("banh")) return "Bánh ngọt";
        return category;
    }

    private String defaultImagePath(String category) {
        String folded = fold(category);
        if (folded.contains("tra")) return "assets/img/menu/tea.jpg";
        if (folded.contains("dac biet")) return "assets/img/menu/matcha.jpg";
        if (folded.contains("banh")) return "assets/img/menu/pastry.jpg";
        return "assets/img/menu/coffee.jpg";
    }

    private String fold(String value) {
        String normalized = java.text.Normalizer.normalize(value == null ? "" : value, java.text.Normalizer.Form.NFD);
        return normalized.replaceAll("\\p{M}", "").replace('đ', 'd').replace('Đ', 'D').toLowerCase(Locale.ROOT);
    }

    public List<Map<String, Object>> getTables() throws Exception {
        return getTables(false);
    }

    public List<Map<String, Object>> getAllTables() throws Exception {
        return getTables(true);
    }

    public List<Map<String, Object>> getTableMap() throws Exception {
        String sql = "SELECT t.id, t.name, t.code, t.active, t.floorNo, t.tableNo, activeOrder.id orderId, activeOrder.orderNumber, activeOrder.status "
                + "FROM dbo.Tables t "
                + "OUTER APPLY (SELECT TOP 1 id, orderNumber, status FROM dbo.Orders WHERE tableName=t.name AND status IN ('Pending','Preparing','Ready','Served','Paid') ORDER BY id DESC) activeOrder "
                + "WHERE t.active=1 AND t.floorNo IS NOT NULL "
                + "ORDER BY t.floorNo, t.tableNo";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            List<Map<String, Object>> tables = rows(rs);
            for (Map<String, Object> table : tables) {
                table.put("busy", table.get("orderId") != null);
            }
            return tables;
        }
    }

    public List<Map<String, Object>> getRunnerTableMap() throws Exception {
        List<Map<String, Object>> full = getTableMap();
        List<Map<String, Object>> sanitized = new ArrayList<>();
        for (Map<String, Object> table : full) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", table.get("id"));
            row.put("name", table.get("name"));
            row.put("floorNo", table.get("floorNo"));
            row.put("tableNo", table.get("tableNo"));
            row.put("status", table.get("status"));
            row.put("busy", table.get("busy"));
            sanitized.add(row);
        }
        return sanitized;
    }

    public List<Map<String, Object>> getOpenOrdersByTable(String tableCode, String tableName) throws Exception {
        String resolvedTable = readString(tableName, "");
        if (!readString(tableCode, "").isEmpty()) {
            Map<String, Object> table = getTableByCode(tableCode);
            if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            resolvedTable = readString(table.get("name"), "");
        }
        if (resolvedTable.isEmpty()) throw new IllegalArgumentException("Không tìm thấy bàn.");
        String sql = "SELECT id, orderNumber, tableName, customerPhone, status, total, note, createdAt, invoicePrinted FROM dbo.Orders "
                + "WHERE tableName=? AND status IN ('Pending','Preparing','Ready','Served','Paid') ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, resolvedTable);
            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String, Object>> list = rows(rs);
                for (Map<String, Object> order : list) {
                    order.put("items", getOrderItems(readInt(order.get("id"), 0)));
                }
                return list;
            }
        }
    }

    public List<Map<String, Object>> getOpenOrdersByIds(List<Integer> orderIds) throws Exception {
        List<Integer> ids = cleanIds(orderIds);
        if (ids.isEmpty()) return new ArrayList<>();
        String sql = "SELECT id, orderNumber, tableName, customerPhone, status, total, note, createdAt, invoicePrinted FROM dbo.Orders "
                + "WHERE id IN (" + placeholders(ids.size()) + ") AND status IN ('Pending','Preparing','Ready','Served','Paid') ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            bindIds(ps, ids);
            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String, Object>> list = rows(rs);
                for (Map<String, Object> order : list) {
                    order.put("items", getOrderItems(readInt(order.get("id"), 0)));
                }
                return list;
            }
        }
    }

    public String currentTableForOrderIds(List<Integer> orderIds) throws Exception {
        List<Integer> ids = cleanIds(orderIds);
        if (ids.isEmpty()) return "";
        String sql = "SELECT TOP 1 tableName FROM dbo.Orders "
                + "WHERE id IN (" + placeholders(ids.size()) + ") AND status IN ('Pending','Preparing','Ready','Served','Paid') ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            bindIds(ps, ids);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? readString(rs.getString("tableName"), "") : "";
            }
        }
    }

    public Map<String, Object> transferTable(int fromTableId, int toTableId) throws Exception {
        return transferTable(fromTableId, toTableId, "system", "system");
    }

    public Map<String, Object> transferTable(int fromTableId, int toTableId, String actorRole, String actorName) throws Exception {
        if (fromTableId == toTableId) throw new IllegalArgumentException("Bàn mới phải khác bàn hiện tại.");
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            Map<String, Object> from = tableRowForUpdate(con, fromTableId);
            Map<String, Object> to = tableRowForUpdate(con, toTableId);
            if (from == null || to == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            if (!readBoolean(from.get("active"), false) || !readBoolean(to.get("active"), false)) {
                throw new IllegalArgumentException("Bàn đã ẩn không thể đổi.");
            }
            String fromName = readString(from.get("name"), "");
            String toName = readString(to.get("name"), "");
            int sourceOrders = countOpenOrders(con, fromName, "('Pending','Preparing','Ready','Served')");
            if (sourceOrders == 0) throw new IllegalArgumentException("Bàn hiện tại không có đơn cần chuyển.");
            int targetOrders = countOpenOrders(con, toName, "('Pending','Preparing','Ready','Served','Paid')");
            if (targetOrders > 0) throw new IllegalArgumentException("Bàn mới đang có khách.");
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET tableName=? WHERE tableName=? AND status IN ('Pending','Preparing','Ready','Served')")) {
                ps.setString(1, toName);
                ps.setString(2, fromName);
                ps.executeUpdate();
            }
            insertSystemLog(con, actorRole, actorName, "TABLE_TRANSFER",
                    "Đổi " + sourceOrders + " đơn từ " + fromName + " sang " + toName + " lúc " + nowLabelVi(),
                    "Moved " + sourceOrders + " order(s) from " + fromName + " to " + toName + " at " + nowLabelEn(),
                    null);
            con.commit();
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("message", "Table transferred");
            result.put("fromTableId", fromTableId);
            result.put("fromTableName", fromName);
            result.put("toTableId", toTableId);
            result.put("toTableName", toName);
            result.put("movedOrders", sourceOrders);
            return result;
        }
    }

    private Map<String, Object> tableRowForUpdate(Connection con, int tableId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT id, name, active, floorNo, tableNo FROM dbo.Tables WITH (UPDLOCK, ROWLOCK) WHERE id=? AND floorNo IS NOT NULL")) {
            ps.setInt(1, tableId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    private int countOpenOrders(Connection con, String tableName, String statuses) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.Orders WHERE tableName=? AND status IN " + statuses)) {
            ps.setString(1, tableName);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    public Map<String, Object> clearServedTable(int tableId) throws Exception {
        return clearServedTable(tableId, "system", "system");
    }

    public Map<String, Object> clearServedTable(int tableId, String actorRole, String actorName) throws Exception {
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            Map<String, Object> table = tableRowForUpdate(con, tableId);
            if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            String tableName = readString(table.get("name"), "");

            int notClearedYet = countOpenOrders(con, tableName, "('Pending','Preparing','Ready','Served')");
            if (notClearedYet > 0) {
                throw new IllegalArgumentException("Bàn vẫn còn đơn đang phục vụ, chưa thể dọn.");
            }

            List<Integer> orderIds = new ArrayList<>();
            List<Integer> orderNumbers = new ArrayList<>();
            try (PreparedStatement ps = con.prepareStatement("SELECT id, orderNumber FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE tableName=? AND status='Paid' ORDER BY id")) {
                ps.setString(1, tableName);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        orderIds.add(rs.getInt("id"));
                        orderNumbers.add(rs.getInt("orderNumber"));
                    }
                }
            }
            if (orderIds.isEmpty()) throw new IllegalArgumentException("Bàn này không có đơn chờ dọn.");

            int clearedCount;
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET status='Cleared' WHERE tableName=? AND status='Paid'")) {
                ps.setString(1, tableName);
                clearedCount = ps.executeUpdate();
                if (clearedCount == 0) {
                    throw new IllegalArgumentException("Bàn này vừa được cập nhật bởi thiết bị khác.");
                }
            }
            String orderLabel = orderNumbers.stream().map(number -> "#" + number).reduce((a, b) -> a + ", " + b).orElse("");
            insertSystemLog(con, actorRole, actorName, "TABLE_CLEAR",
                    "Bồi bàn dọn xong " + tableName + " cho " + clearedCount + " hóa đơn " + orderLabel + " lúc " + nowLabelVi(),
                    "Waiter cleared " + tableName + " for " + clearedCount + " bill(s) " + orderLabel + " at " + nowLabelEn(),
                    orderIds.get(0));
            con.commit();
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("message", "Table ready");
            result.put("tableId", tableId);
            result.put("tableName", tableName);
            result.put("busy", false);
            result.put("status", "Available");
            result.put("orderId", orderIds.get(0));
            result.put("orderNumber", orderNumbers.get(0));
            result.put("orderIds", orderIds);
            result.put("orderNumbers", orderNumbers);
            result.put("clearedOrders", clearedCount);
            result.put("orderStatus", "Cleared");
            return result;
        }
    }

    private List<Map<String, Object>> getTables(boolean includeInactive) throws Exception {
        String where = includeInactive ? "WHERE floorNo IS NOT NULL AND tableNo IS NOT NULL " : "WHERE active=1 AND floorNo IS NOT NULL AND tableNo IS NOT NULL ";
        String sql = "SELECT id, name, code, active, floorNo, tableNo FROM dbo.Tables " + where + "ORDER BY floorNo, tableNo";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            return rows(rs);
        }
    }

    public Map<String, Object> getTableByCode(String code) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, name, code, active, floorNo, tableNo FROM dbo.Tables WHERE code=? AND active=1")) {
            ps.setString(1, readString(code, ""));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    public Map<String, Object> getTableByName(String name) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, name, code, active, floorNo, tableNo FROM dbo.Tables WHERE name=? AND active=1")) {
            ps.setString(1, readString(name, ""));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    public Map<String, Object> getTableById(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, name, code, active, floorNo, tableNo FROM dbo.Tables WHERE id=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : null;
            }
        }
    }

    public Map<String, Object> saveTable(Map<String, Object> data) throws Exception {
        int id = readInt(data.get("id"), 0);
        String name = readString(data.get("name"), "");
        int floorNo = readInt(data.get("floorNo"), 0);
        int tableNo = readInt(data.get("tableNo"), 0);
        int[] parsed = parseTableLocation(name);
        if (floorNo <= 0 && parsed[0] > 0) floorNo = parsed[0];
        if (tableNo <= 0 && parsed[1] > 0) tableNo = parsed[1];
        if (floorNo <= 0) floorNo = 1;
        if (tableNo <= 0) throw new IllegalArgumentException("Số bàn không hợp lệ.");
        if (name.isEmpty()) name = "Tầng " + floorNo + " - Bàn " + tableNo;
        boolean active = readBoolean(data.get("active"), true);
        validateTable(id, name, floorNo, tableNo);

        try (Connection con = db.getConnection()) {
            if (tableLocationExists(con, id, floorNo, tableNo)) {
                throw new IllegalArgumentException("Vị trí bàn này đã tồn tại.");
            }
            if (id > 0) {
                try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Tables SET name=?, active=?, floorNo=?, tableNo=? WHERE id=?")) {
                    ps.setString(1, name);
                    ps.setBoolean(2, active);
                    ps.setInt(3, floorNo);
                    ps.setInt(4, tableNo);
                    ps.setInt(5, id);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.Tables (name, code, active, floorNo, tableNo) VALUES (?,?,?,?,?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, name);
                    ps.setString(2, uniqueTableCode(con));
                    ps.setBoolean(3, active);
                    ps.setInt(4, floorNo);
                    ps.setInt(5, tableNo);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (keys.next()) id = keys.getInt(1);
                    }
                }
            }
        }
        return getTableById(id);
    }

    private void validateTable(int id, String name, int floorNo, int tableNo) {
        if (name.length() < 2 || name.length() > 60) throw new IllegalArgumentException("Tên bàn phải từ 2 đến 60 ký tự.");
        if (floorNo < 1 || floorNo > 10) throw new IllegalArgumentException("Tầng phải từ 1 đến 10.");
        if (tableNo < 1 || tableNo > 99) throw new IllegalArgumentException("Số bàn phải từ 1 đến 99.");
    }

    private boolean tableLocationExists(Connection con, int id, int floorNo, int tableNo) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM dbo.Tables WHERE id<>? AND floorNo=? AND tableNo=?")) {
            ps.setInt(1, id);
            ps.setInt(2, floorNo);
            ps.setInt(3, tableNo);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    private int[] parseTableLocation(String name) {
        String text = readString(name, "");
        java.util.regex.Matcher match = java.util.regex.Pattern.compile("Tầng\\s*(\\d+)\\s*-\\s*Bàn\\s*(\\d+)", java.util.regex.Pattern.CASE_INSENSITIVE | java.util.regex.Pattern.UNICODE_CASE).matcher(text);
        if (match.find()) return new int[] { readInt(match.group(1), 0), readInt(match.group(2), 0) };
        match = java.util.regex.Pattern.compile("Bàn\\s*(\\d+)", java.util.regex.Pattern.CASE_INSENSITIVE | java.util.regex.Pattern.UNICODE_CASE).matcher(text);
        if (match.find()) return new int[] { 1, readInt(match.group(1), 0) };
        return new int[] { 0, 0 };
    }

    public Map<String, Object> regenerateTableCode(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("UPDATE dbo.Tables SET code=? WHERE id=?")) {
            ps.setString(1, uniqueTableCode(con));
            ps.setInt(2, id);
            ps.executeUpdate();
        }
        return getTableById(id);
    }

    public void deleteTable(int id) throws Exception {
        try (Connection con = db.getConnection()) {
            Map<String, Object> table = getTableById(id);
            if (table == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
            String name = readString(table.get("name"), "");
            int activeOrders = countOpenOrders(con, name, "('Pending','Preparing','Ready','Served','Paid')");
            if (activeOrders > 0) throw new IllegalArgumentException("Bàn đang có đơn, không thể xoá.");
            try (PreparedStatement ps = con.prepareStatement("DELETE FROM dbo.Tables WHERE id=?")) {
                ps.setInt(1, id);
                ps.executeUpdate();
            }
        }
    }

    public Map<String, Object> createOrder(Map<String, Object> data) throws Exception {
        return createOrder(data, "guest", "");
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> createOrder(Map<String, Object> data, String actorRole, String actorName) throws Exception {
        String tableName = readString(data.get("tableName"), "Bàn 1");
        if (getTableByName(tableName) == null) throw new IllegalArgumentException("Không tìm thấy bàn.");
        String phone = readString(data.get("customerPhone"), "");
        String note = limitNote(readString(data.get("note"), ""));
        List<?> items = data.get("items") instanceof List<?> ? (List<?>) data.get("items") : Collections.emptyList();
        if (items.isEmpty()) throw new IllegalArgumentException("Đơn hàng chưa có món.");

        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            try {
                int orderId;
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.Orders (tableName,customerPhone,note,total,createdAt) VALUES (?,?,?,0,?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, tableName);
                    ps.setString(2, phone.isEmpty() ? null : phone);
                    ps.setString(3, note);
                    ps.setString(4, nowSqlTimestamp());
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        keys.next();
                        orderId = keys.getInt(1);
                    }
                }

                int total = 0;
                int totalQuantity = 0;
                Map<String, Integer> variantQuantities = new LinkedHashMap<>();
                Map<Integer, Integer> requestedByMenu = new LinkedHashMap<>();
                Map<Integer, String> menuNames = new LinkedHashMap<>();
                List<Map<String, Object>> normalizedLines = new ArrayList<>();
                Map<String, Integer> stockMap = getIngredientStockMap(con);
                Map<Integer, Integer> reservedMap = getReservedMenuQuantityMap(con);
                dao.RecipeDAO recipeDao = new dao.RecipeDAO();

                for (Object raw : items) {
                    if (!(raw instanceof Map<?, ?>)) continue;
                    Map<?, ?> item = (Map<?, ?>) raw;
                    int menuId = readInt(item.get("menuItemId"), 0);
                    int requestedQuantity = readInt(item.get("quantity"), 1);
                    if (requestedQuantity < 1) {
                        throw new IllegalArgumentException("Số lượng món phải lớn hơn 0.");
                    }
                    if (requestedQuantity > MAX_ITEM_QUANTITY) {
                        throw new IllegalArgumentException("Mỗi món chỉ được chọn tối đa " + MAX_ITEM_QUANTITY + " sản phẩm.");
                    }
                    int quantity = requestedQuantity;
                    Map<String, Object> menu = getMenuItem(menuId);
                    if (menu == null) {
                        throw new IllegalArgumentException("Món không tồn tại hoặc đã bị xoá.");
                    }
                    if (!readBoolean(menu.get("active"), false)) {
                        String itemName = readString(menu.get("nameVi"), "");
                        throw new IllegalArgumentException(itemName.isEmpty()
                                ? "Món hiện không còn phục vụ."
                                : ("Món \"" + itemName + "\" hiện không còn phục vụ."));
                    }
                    String size = normalizeSize(menu, readString(item.get("size"), ""));
                    String variantKey = menuId + "|" + size;
                    int variantTotal = variantQuantities.getOrDefault(variantKey, 0) + quantity;
                    if (variantTotal > MAX_ITEM_QUANTITY) {
                        throw new IllegalArgumentException("Mỗi món chỉ được chọn tối đa " + MAX_ITEM_QUANTITY + " sản phẩm.");
                    }
                    variantQuantities.put(variantKey, variantTotal);
                    requestedByMenu.put(menuId, requestedByMenu.getOrDefault(menuId, 0) + quantity);
                    menuNames.put(menuId, readString(menu.get("nameVi"), ""));
                    Map<String, Object> line = new LinkedHashMap<>();
                    line.put("menu", menu);
                    line.put("menuId", menuId);
                    line.put("size", size);
                    line.put("quantity", quantity);
                    line.put("price", priceForSize(menu, size));
                    normalizedLines.add(line);
                }

                for (Map.Entry<Integer, Integer> entry : requestedByMenu.entrySet()) {
                    int menuId = entry.getKey();
                    int requested = entry.getValue();
                    List<model.RecipeItem> recipes = recipeDao.getByMenuItemId(String.valueOf(menuId));
                    int available = availableQuantity(recipes, stockMap, reservedMap.getOrDefault(menuId, 0));
                    if (!recipes.isEmpty() && requested > available) {
                        String itemName = menuNames.getOrDefault(menuId, "");
                        if (available <= 0) {
                            throw new IllegalArgumentException(itemName.isEmpty()
                                    ? "Món hiện không còn đủ hàng để phục vụ."
                                    : ("Món \"" + itemName + "\" hiện không còn đủ hàng để phục vụ."));
                        }
                        throw new IllegalArgumentException(itemName.isEmpty()
                                ? ("Chỉ còn " + available + " suất, không đủ số lượng đã chọn.")
                                : ("Món \"" + itemName + "\" chỉ còn " + available + " suất, không đủ số lượng đã chọn."));
                    }
                }

                for (Map<String, Object> line : normalizedLines) {
                    Map<String, Object> menu = (Map<String, Object>) line.get("menu");
                    int menuId = readInt(line.get("menuId"), 0);
                    String size = readString(line.get("size"), "");
                    int quantity = readInt(line.get("quantity"), 0);
                    int price = readInt(line.get("price"), 0);
                    total += price * quantity;
                    totalQuantity += quantity;
                    try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.OrderItems (orderId,menuItemId,itemName,itemSize,quantity,price) VALUES (?,?,?,?,?,?)")) {
                        ps.setInt(1, orderId);
                        ps.setInt(2, menuId);
                        ps.setString(3, readString(menu.get("nameVi"), ""));
                        ps.setString(4, size.isEmpty() ? null : size);
                        ps.setInt(5, quantity);
                        ps.setInt(6, price);
                        ps.executeUpdate();
                    }
                }
                if (totalQuantity == 0) throw new IllegalArgumentException("Đơn hàng chưa có món hợp lệ.");
                int orderNumber = 1000 + orderId;
                try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET orderNumber=?, total=? WHERE id=?")) {
                    ps.setInt(1, orderNumber);
                    ps.setInt(2, total);
                    ps.setInt(3, orderId);
                    ps.executeUpdate();
                }
                String actor = normalizeActor(actorRole);
                if (actor.isEmpty() || "system".equals(actor)) actor = "guest";
                String actorDisplay = readString(actorName, "");
                if (actorDisplay.isEmpty()) actorDisplay = "guest".equals(actor) ? (phone.isEmpty() ? "Khách" : phone) : roleNameVi(actor);
                insertSystemLog(con, actor, actorDisplay, "ORDER_CREATE",
                        orderCreateLogVi(actor, tableName, orderNumber, totalQuantity),
                        orderCreateLogEn(actor, tableName, orderNumber, totalQuantity),
                        orderId);
                deactivateUnavailableMenuItems(con, requestedByMenu.keySet());
                con.commit();
                return getOrderById(orderId);
            } catch (Exception e) {
                con.rollback();
                throw e;
            }
        }
    }

    public List<Map<String, Object>> getOrders() throws Exception {
        return getOrders("");
    }

    public List<Map<String, Object>> getOrders(String role) throws Exception {
        return getOrders(role, null);
    }

    public List<Map<String, Object>> getOrders(String role, List<Integer> cashierSessionPaidIds) throws Exception {
        String sql = "SELECT id, orderNumber, tableName, customerPhone, status, total, note, createdAt, invoicePrinted FROM dbo.Orders ";
        if ("barista".equals(role)) {
            sql += "WHERE status IN ('Pending','Preparing','Ready') ";
        } else if ("cashier".equals(role)) {
            String sessionPaid = paidIdList(cashierSessionPaidIds);
            sql += sessionPaid.isEmpty()
                    ? "WHERE status='Served' "
                    : "WHERE status='Served' OR id IN (" + sessionPaid + ") ";
        } else if ("runner".equals(role)) {
            sql += "WHERE status IN ('Ready','Served','Paid') ";
        }
        sql += "ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            List<Map<String, Object>> list = rows(rs);
            for (Map<String, Object> order : list) {
                order.put("items", getOrderItems(readInt(order.get("id"), 0)));
                if ("cashier".equals(role)) {
                    String tableName = readString(order.get("tableName"), "");
                    order.put("blockingOrders", countOpenOrders(con, tableName, "('Pending','Preparing','Ready')"));
                }
            }
            if ("runner".equals(role)) sanitizeRunnerOrders(list);
            return list;
        }
    }

    private String paidIdList(List<Integer> ids) {
        if (ids == null || ids.isEmpty()) return "";
        StringJoiner joiner = new StringJoiner(",");
        Set<Integer> unique = new LinkedHashSet<>();
        for (Integer id : ids) {
            if (id != null && id > 0) unique.add(id);
        }
        for (Integer id : unique) joiner.add(String.valueOf(id));
        return joiner.toString();
    }

    @SuppressWarnings("unchecked")
    private void sanitizeRunnerOrders(List<Map<String, Object>> orders) {
        for (Map<String, Object> order : orders) {
            order.remove("total");
            order.remove("customerPhone");
            List<Map<String, Object>> items = (List<Map<String, Object>>) order.get("items");
            if (items == null) continue;
            for (Map<String, Object> item : items) {
                item.remove("price");
            }
        }
    }

    public Map<String, Object> getOrderByNumber(int orderNumber) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id FROM dbo.Orders WHERE orderNumber=?")) {
            ps.setInt(1, orderNumber);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? getOrderById(rs.getInt("id")) : null;
            }
        }
    }

    public Map<String, Object> updateOrderStatus(int id, String status) throws Exception {
        return updateOrderStatus(id, status, "system", "system");
    }

    public Map<String, Object> updateOrderStatus(int id, String status, String actorRole, String actorName) throws Exception {
        if (!Arrays.asList("Pending", "Preparing", "Ready", "Served", "Paid", "Cleared").contains(status)) {
            throw new IllegalArgumentException("Trạng thái đơn không hợp lệ.");
        }
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            String currentStatus = "";
            int total = 0;
            int orderNumber = 0;
            String tableName = "";
            try (PreparedStatement ps = con.prepareStatement("SELECT status,total,orderNumber,tableName FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE id=?")) {
                ps.setInt(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
                    currentStatus = rs.getString("status");
                    total = rs.getInt("total");
                    orderNumber = rs.getInt("orderNumber");
                    tableName = rs.getString("tableName");
                }
            }
            if ("Preparing".equals(currentStatus) && "Ready".equals(status)) {
                int requiredCups = cupCountForOrder(con, id);
                int cups = stateValueForUpdate(con, "cupsAvailable", 0);
                if (requiredCups > cups) {
                    throw new IllegalArgumentException("Đơn này cần " + requiredCups + " cốc, hiện chỉ còn " + cups + " cốc.");
                }
                if (requiredCups > 0) {
                    setStateValue(con, "cupsAvailable", cups - requiredCups);
                }
                deductInventoryForOrder(con, id);
                deactivateUnavailableMenuItems(con, null);
            }
            if ("Served".equals(currentStatus) && "Paid".equals(status)) {
                int notServedYet = countOpenOrders(con, tableName, "('Pending','Preparing','Ready')");
                if (notServedYet > 0) {
                    throw new IllegalStateException("Bàn vẫn còn món chưa phục vụ, chưa thể thanh toán.");
                }
            }
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET status=? WHERE id=?")) {
                ps.setString(1, status);
                ps.setInt(2, id);
                ps.executeUpdate();
            }
            insertSystemLog(con, actorRole, actorName, "ORDER_STATUS",
                    statusLogVi(actorRole, currentStatus, status, orderNumber, tableName),
                    statusLogEn(actorRole, currentStatus, status, orderNumber, tableName),
                    id);
            int resultOrderId = id;
            if ("Ready".equals(currentStatus) && "Served".equals(status)) {
                resultOrderId = consolidateServedBillsForTable(con, tableName, id, actorRole, actorName);
            }
            con.commit();
            return getOrderById(resultOrderId);
        }
    }

    private void deductInventoryForOrder(Connection con, int orderId) throws Exception {
        Map<String, Integer> deductions = new LinkedHashMap<>();
        String sql = "SELECT ri.ingredientId, SUM(ri.quantity * oi.quantity) usedQuantity "
                + "FROM dbo.OrderItems oi "
                + "JOIN dbo.RecipeItems ri ON ri.menuItemId = CONVERT(VARCHAR(50), oi.menuItemId) "
                + "WHERE oi.orderId=? "
                + "GROUP BY ri.ingredientId";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    deductions.put(rs.getString("ingredientId"), Math.max(0, rs.getInt("usedQuantity")));
                }
            }
        }
        for (Map.Entry<String, Integer> entry : deductions.entrySet()) {
            int amount = entry.getValue();
            if (amount <= 0) continue;
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Inventory SET stock = CASE WHEN stock >= ? THEN stock - ? ELSE 0 END WHERE id=?")) {
                ps.setInt(1, amount);
                ps.setInt(2, amount);
                ps.setString(3, entry.getKey());
                ps.executeUpdate();
            }
        }
    }

    public List<Map<String, Object>> getLowStockIngredients() throws Exception {
        try (Connection con = db.getConnection()) {
            return getLowStockIngredients(con);
        }
    }

    public int refreshMenuAvailability() throws Exception {
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            try {
                int disabled = deactivateUnavailableMenuItems(con, null);
                con.commit();
                return disabled;
            } catch (Exception e) {
                con.rollback();
                throw e;
            }
        }
    }

    private List<Map<String, Object>> getLowStockIngredients(Connection con) throws Exception {
        String sql = "SELECT id, name, unit, stock, minStock, importCost FROM dbo.Inventory "
                + "WHERE stock <= minStock ORDER BY stock ASC, name ASC";
        try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            return rows(rs);
        }
    }

    private Map<String, Integer> getIngredientStockMap(Connection con) throws Exception {
        Map<String, Integer> stock = new LinkedHashMap<>();
        try (PreparedStatement ps = con.prepareStatement("SELECT id, stock FROM dbo.Inventory");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                stock.put(rs.getString("id"), Math.max(0, rs.getInt("stock")));
            }
        }
        return stock;
    }

    private Map<Integer, Integer> getReservedMenuQuantityMap(Connection con) throws Exception {
        Map<Integer, Integer> reserved = new LinkedHashMap<>();
        String sql = "SELECT oi.menuItemId, SUM(oi.quantity) quantity "
                + "FROM dbo.OrderItems oi "
                + "JOIN dbo.Orders o ON o.id = oi.orderId "
                + "WHERE o.status IN ('Pending','Preparing') AND oi.menuItemId IS NOT NULL AND oi.menuItemId > 0 "
                + "GROUP BY oi.menuItemId";
        try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                reserved.put(rs.getInt("menuItemId"), Math.max(0, rs.getInt("quantity")));
            }
        }
        return reserved;
    }

    private int availableQuantity(List<model.RecipeItem> recipes, Map<String, Integer> stockMap, int reservedServings) {
        if (recipes == null || recipes.isEmpty()) return MAX_ITEM_QUANTITY;
        int maxByStock = Integer.MAX_VALUE;
        boolean hasRequirement = false;
        for (model.RecipeItem recipe : recipes) {
            int need = Math.max(0, recipe.getQuantity());
            if (need <= 0) continue;
            hasRequirement = true;
            int stock = stockMap.getOrDefault(recipe.getIngredientId(), 0);
            maxByStock = Math.min(maxByStock, stock / need);
        }
        if (!hasRequirement) return MAX_ITEM_QUANTITY;
        return Math.max(0, Math.min(MAX_ITEM_QUANTITY, maxByStock - Math.max(0, reservedServings)));
    }

    private int deactivateUnavailableMenuItems(Connection con, Collection<Integer> menuItemIds) throws Exception {
        Map<String, Integer> stockMap = getIngredientStockMap(con);
        Map<Integer, Integer> reservedMap = getReservedMenuQuantityMap(con);
        dao.RecipeDAO recipeDao = new dao.RecipeDAO();
        java.util.Map<String, java.util.List<model.RecipeItem>> allRecipes = recipeDao.getAllRecipesMappedByMenuItemId();
        List<Integer> candidates = new ArrayList<>();
        if (menuItemIds == null) {
            try (PreparedStatement ps = con.prepareStatement("SELECT id FROM dbo.MenuItems WHERE active=1");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) candidates.add(rs.getInt("id"));
            }
        } else {
            for (Integer id : menuItemIds) {
                if (id != null && id > 0) candidates.add(id);
            }
        }
        int disabled = 0;
        for (Integer menuId : candidates) {
            List<model.RecipeItem> recipes = allRecipes.getOrDefault(String.valueOf(menuId), new ArrayList<>());
            if (recipes.isEmpty()) continue;
            int available = availableQuantity(recipes, stockMap, reservedMap.getOrDefault(menuId, 0));
            if (available > 0) continue;
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.MenuItems SET active=0 WHERE id=? AND active=1")) {
                ps.setInt(1, menuId);
                disabled += ps.executeUpdate();
            }
        }
        return disabled;
    }

    private String nowSqlTimestamp() {
        return java.time.LocalDateTime.now(APP_ZONE).format(SQL_TIMESTAMP_FORMAT);
    }

    private LocalDate appToday() {
        return LocalDate.now(APP_ZONE);
    }

    private int consolidateServedBillsForTable(Connection con, String tableName, int preferredOrderId, String actorRole, String actorName) throws Exception {
        List<Integer> servedIds = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement("SELECT id FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE tableName=? AND status='Served' AND splitLocked=0 ORDER BY id")) {
            ps.setString(1, tableName);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) servedIds.add(rs.getInt("id"));
            }
        }
        if (servedIds.size() <= 1) return preferredOrderId;

        int targetId = servedIds.get(0);
        for (Integer sourceId : servedIds) {
            if (sourceId != null && sourceId > 0 && sourceId != targetId) {
                mergeServedOrderInto(con, sourceId, targetId, actorRole, actorName);
            }
        }
        return targetId;
    }

    private void mergeServedOrderInto(Connection con, int sourceId, int targetId, String actorRole, String actorName) throws Exception {
        Map<String, Object> source = orderMergeInfo(con, sourceId);
        Map<String, Object> target = orderMergeInfo(con, targetId);
        if (source.isEmpty() || target.isEmpty()) return;

        int sourceTotal = readInt(source.get("total"), 0);
        int sourceNumber = readInt(source.get("orderNumber"), 0);
        int targetNumber = readInt(target.get("orderNumber"), 0);
        String sourceNote = readString(source.get("note"), "");
        String targetNote = readString(target.get("note"), "");
        String sourcePhone = readString(source.get("customerPhone"), "");
        String targetPhone = readString(target.get("customerPhone"), "");
        String tableName = readString(target.get("tableName"), "");

        moveOrderItemsToMergedBill(con, sourceId, targetId);

        try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET total=total+?, note=?, customerPhone=? WHERE id=? AND status='Served'")) {
            ps.setInt(1, sourceTotal);
            ps.setString(2, mergedNote(targetNote, sourceNote));
            String phone = targetPhone.isEmpty() ? sourcePhone : targetPhone;
            ps.setString(3, phone.isEmpty() ? null : phone);
            ps.setInt(4, targetId);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET status='Merged', total=0 WHERE id=? AND status='Served'")) {
            ps.setInt(1, sourceId);
            ps.executeUpdate();
        }
        insertSystemLog(con, actorRole, actorName, "ORDER_MERGE",
                "Gộp đơn #" + sourceNumber + " vào hóa đơn #" + targetNumber + " của " + tableName + " lúc " + nowLabelVi(),
                "Merged order #" + sourceNumber + " into bill #" + targetNumber + " at " + tableName + " at " + nowLabelEn(),
                targetId);
    }

    private Map<String, Object> orderMergeInfo(Connection con, int orderId) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT id, orderNumber, tableName, customerPhone, total, note FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE id=? AND status='Served'")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? row(rs) : new LinkedHashMap<>();
            }
        }
    }

    private void moveOrderItemsToMergedBill(Connection con, int sourceId, int targetId) throws Exception {
        List<Map<String, Object>> sourceItems = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement("SELECT menuItemId, itemName, itemSize, quantity, price FROM dbo.OrderItems WHERE orderId=? ORDER BY id")) {
            ps.setInt(1, sourceId);
            try (ResultSet rs = ps.executeQuery()) {
                sourceItems = rows(rs);
            }
        }
        for (Map<String, Object> item : sourceItems) {
            int existingId = findMatchingOrderItem(con, targetId, readInt(item.get("menuItemId"), 0), readString(item.get("itemSize"), ""), readInt(item.get("price"), 0));
            int quantity = Math.max(0, readInt(item.get("quantity"), 0));
            if (existingId > 0) {
                try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.OrderItems SET quantity=quantity+? WHERE id=?")) {
                    ps.setInt(1, quantity);
                    ps.setInt(2, existingId);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.OrderItems (orderId,menuItemId,itemName,itemSize,quantity,price) VALUES (?,?,?,?,?,?)")) {
                    ps.setInt(1, targetId);
                    ps.setInt(2, readInt(item.get("menuItemId"), 0));
                    ps.setString(3, readString(item.get("itemName"), ""));
                    String size = readString(item.get("itemSize"), "");
                    ps.setString(4, size.isEmpty() ? null : size);
                    ps.setInt(5, quantity);
                    ps.setInt(6, readInt(item.get("price"), 0));
                    ps.executeUpdate();
                }
            }
        }
        try (PreparedStatement ps = con.prepareStatement("DELETE FROM dbo.OrderItems WHERE orderId=?")) {
            ps.setInt(1, sourceId);
            ps.executeUpdate();
        }
    }

    private int findMatchingOrderItem(Connection con, int orderId, int menuItemId, String size, int price) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT TOP 1 id FROM dbo.OrderItems WHERE orderId=? AND menuItemId=? AND ISNULL(itemSize,'')=? AND price=? ORDER BY id")) {
            ps.setInt(1, orderId);
            ps.setInt(2, menuItemId);
            ps.setString(3, readString(size, ""));
            ps.setInt(4, price);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("id") : 0;
            }
        }
    }

    public Map<String, Object> splitOrder(int sourceOrderId, List<Map<String, Object>> selections, String actorRole, String actorName) throws Exception {
        if (selections == null || selections.isEmpty()) {
            throw new IllegalArgumentException("Chưa chọn món nào để tách.");
        }
        // Gộp số lượng theo orderItemId để tránh trùng dòng trong lựa chọn.
        Map<Integer, Integer> wanted = new LinkedHashMap<>();
        for (Map<String, Object> sel : selections) {
            int itemId = readInt(sel.get("id"), 0);
            int qty = readInt(sel.get("quantity"), 0);
            if (itemId <= 0 || qty <= 0) continue;
            wanted.merge(itemId, qty, Integer::sum);
        }
        if (wanted.isEmpty()) {
            throw new IllegalArgumentException("Số lượng tách không hợp lệ.");
        }

        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);

            int sourceNumber;
            String tableName;
            try (PreparedStatement ps = con.prepareStatement("SELECT orderNumber, tableName FROM dbo.Orders WITH (UPDLOCK, ROWLOCK) WHERE id=? AND status='Served'")) {
                ps.setInt(1, sourceOrderId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new IllegalArgumentException("Chỉ tách được hóa đơn đang chờ thanh toán.");
                    sourceNumber = rs.getInt("orderNumber");
                    tableName = rs.getString("tableName");
                }
            }

            // Đọc & khóa các dòng của đơn nguồn.
            Map<Integer, Map<String, Object>> sourceLines = new LinkedHashMap<>();
            try (PreparedStatement ps = con.prepareStatement("SELECT id, menuItemId, itemName, itemSize, quantity, price FROM dbo.OrderItems WITH (UPDLOCK, ROWLOCK) WHERE orderId=? ORDER BY id")) {
                ps.setInt(1, sourceOrderId);
                try (ResultSet rs = ps.executeQuery()) {
                    for (Map<String, Object> line : rows(rs)) {
                        sourceLines.put(readInt(line.get("id"), 0), line);
                    }
                }
            }
            if (sourceLines.isEmpty()) throw new IllegalArgumentException("Hóa đơn nguồn không có món.");

            // Validate lựa chọn thuộc đơn nguồn và số lượng hợp lệ; đồng thời kiểm tra không tách hết mọi thứ.
            boolean leavesRemainder = false;
            for (Map.Entry<Integer, Map<String, Object>> entry : sourceLines.entrySet()) {
                int available = readInt(entry.getValue().get("quantity"), 0);
                int take = wanted.getOrDefault(entry.getKey(), 0);
                if (take < available) leavesRemainder = true;
            }
            for (Map.Entry<Integer, Integer> req : wanted.entrySet()) {
                Map<String, Object> line = sourceLines.get(req.getKey());
                if (line == null) throw new IllegalArgumentException("Món tách không thuộc hóa đơn này.");
                int available = readInt(line.get("quantity"), 0);
                if (req.getValue() > available) {
                    throw new IllegalArgumentException("Số lượng tách vượt quá số lượng của món.");
                }
            }
            if (!leavesRemainder) {
                throw new IllegalArgumentException("Phải để lại ít nhất 1 món trên hóa đơn gốc.");
            }

            // Tạo hóa đơn mới (đã khóa để tránh auto-gộp lại).
            int newId;
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.Orders (tableName,customerPhone,note,total,status,splitLocked) VALUES (?,NULL,?,0,'Served',1)", Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, tableName);
                ps.setString(2, limitNote("Tách từ #" + sourceNumber));
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    keys.next();
                    newId = keys.getInt(1);
                }
            }

            // Chuyển số lượng sang hóa đơn mới.
            for (Map.Entry<Integer, Integer> req : wanted.entrySet()) {
                Map<String, Object> line = sourceLines.get(req.getKey());
                int take = req.getValue();
                int available = readInt(line.get("quantity"), 0);
                if (take >= available) {
                    try (PreparedStatement ps = con.prepareStatement("DELETE FROM dbo.OrderItems WHERE id=?")) {
                        ps.setInt(1, req.getKey());
                        ps.executeUpdate();
                    }
                } else {
                    try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.OrderItems SET quantity=quantity-? WHERE id=?")) {
                        ps.setInt(1, take);
                        ps.setInt(2, req.getKey());
                        ps.executeUpdate();
                    }
                }
                int menuItemId = readInt(line.get("menuItemId"), 0);
                String size = readString(line.get("itemSize"), "");
                int price = readInt(line.get("price"), 0);
                int existingId = findMatchingOrderItem(con, newId, menuItemId, size, price);
                if (existingId > 0) {
                    try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.OrderItems SET quantity=quantity+? WHERE id=?")) {
                        ps.setInt(1, take);
                        ps.setInt(2, existingId);
                        ps.executeUpdate();
                    }
                } else {
                    try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.OrderItems (orderId,menuItemId,itemName,itemSize,quantity,price) VALUES (?,?,?,?,?,?)")) {
                        ps.setInt(1, newId);
                        ps.setInt(2, menuItemId);
                        ps.setString(3, readString(line.get("itemName"), ""));
                        ps.setString(4, size.isEmpty() ? null : size);
                        ps.setInt(5, take);
                        ps.setInt(6, price);
                        ps.executeUpdate();
                    }
                }
            }

            // Tính lại tổng cho cả hai hóa đơn và khóa đơn gốc khỏi auto-gộp.
            updateOrderTotal(con, sourceOrderId);
            updateOrderTotal(con, newId);
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET orderNumber=?, splitLocked=1 WHERE id=?")) {
                ps.setInt(1, 1000 + newId);
                ps.setInt(2, newId);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET splitLocked=1 WHERE id=?")) {
                ps.setInt(1, sourceOrderId);
                ps.executeUpdate();
            }

            insertSystemLog(con, actorRole, actorName, "ORDER_SPLIT",
                    "Tách hóa đơn #" + sourceNumber + " thành hóa đơn mới #" + (1000 + newId) + " tại " + tableName + " lúc " + nowLabelVi(),
                    "Split bill #" + sourceNumber + " into new bill #" + (1000 + newId) + " at " + tableName + " at " + nowLabelEn(),
                    newId);
            con.commit();

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("source", getOrderById(sourceOrderId));
            result.put("created", getOrderById(newId));
            return result;
        }
    }

    private void updateOrderTotal(Connection con, int orderId) throws Exception {
        int total = 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT ISNULL(SUM(quantity*price),0) AS total FROM dbo.OrderItems WHERE orderId=?")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) total = rs.getInt("total");
            }
        }
        try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET total=? WHERE id=?")) {
            ps.setInt(1, total);
            ps.setInt(2, orderId);
            ps.executeUpdate();
        }
    }

    private String mergedNote(String targetNote, String sourceNote) {
        String target = readString(targetNote, "");
        String source = readString(sourceNote, "");
        if (target.isEmpty()) return limitNote(source);
        if (source.isEmpty()) return limitNote(target);
        return limitNote(target + ", " + source);
    }

    private int cupCountForOrder(Connection con, int orderId) throws Exception {
        String sql = "SELECT oi.quantity, mi.category "
                + "FROM dbo.OrderItems oi "
                + "JOIN dbo.MenuItems mi ON mi.id=oi.menuItemId "
                + "WHERE oi.orderId=?";
        int cups = 0;
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    if (isDrinkCategory(rs.getString("category"))) {
                        cups += Math.max(0, rs.getInt("quantity"));
                    }
                }
            }
        }
        return cups;
    }

    public Map<String, Object> getCashStatus(String role) throws Exception {
        try (Connection con = db.getConnection()) {
            Map<String, Object> status = new LinkedHashMap<>();
            status.put("balance", currentCashBalance(con));
            status.put("recentWithdrawals", cashEvents(con, "ADMIN_WITHDRAW", 8, false));
            status.put("recentEvents", cashEvents(con, "", 12, false));
            status.put("pendingWithdrawals", "cashier".equals(role) ? cashEvents(con, "ADMIN_WITHDRAW", 8, true) : new ArrayList<>());
            return status;
        }
    }

    public Map<String, Object> recordCashierCount(int countedCash, String actorName) throws Exception {
        if (countedCash < 0 || countedCash > 1000000000) throw new IllegalArgumentException("Số tiền mặt không hợp lệ.");
        try (Connection con = db.getConnection()) {
            int current = currentCashBalance(con);
            int diff = countedCash - current;
            insertCashEvent(con, "CASHIER_COUNT", diff, countedCash, "Cashier cash count", "cashier", actorName, true);
            insertSystemLog(con, "cashier", actorName, "CASH_COUNT",
                    "Thu ngân chốt tiền mặt " + countedCash + "đ lúc " + nowLabelVi(),
                    "Cashier counted cash at " + countedCash + " VND at " + nowLabelEn(),
                    null);
            return getCashStatus("cashier");
        }
    }

    public Map<String, Object> withdrawCash(int amount, String actorName) throws Exception {
        if (amount <= 0 || amount > 1000000000) throw new IllegalArgumentException("Số tiền rút không hợp lệ.");
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            int current = currentCashBalance(con);
            if (amount > current) throw new IllegalArgumentException("Số tiền rút lớn hơn tiền mặt hiện có.");
            int balance = current - amount;
            insertCashEvent(con, "ADMIN_WITHDRAW", -amount, balance, "Admin withdraw", "admin", actorName, false);
            insertSystemLog(con, "admin", actorName, "CASH_WITHDRAW",
                    "Admin rút " + amount + "đ tiền mặt lúc " + nowLabelVi(),
                    "Admin withdrew " + amount + " VND cash at " + nowLabelEn(),
                    null);
            con.commit();
            return getCashStatus("admin");
        }
    }

    public void acknowledgeCashierWithdrawals() throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("UPDATE dbo.CashEvents SET seenByCashier=1 WHERE eventType='ADMIN_WITHDRAW' AND seenByCashier=0")) {
            ps.executeUpdate();
        }
    }

    private int currentCashBalance(Connection con) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("SELECT TOP 1 balanceAfter FROM dbo.CashEvents WHERE eventType IN ('CASHIER_COUNT','ADMIN_WITHDRAW') ORDER BY id DESC");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt("balanceAfter") : 0;
        }
    }

    private void insertCashEvent(Connection con, String type, int amount, int balanceAfter, String note, String actorRole, String actorName, boolean seenByCashier) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.CashEvents (eventType,amount,balanceAfter,note,actorRole,actorName,seenByCashier) VALUES (?,?,?,?,?,?,?)")) {
            ps.setString(1, type);
            ps.setInt(2, amount);
            ps.setInt(3, balanceAfter);
            ps.setString(4, limitNote(note));
            ps.setString(5, actorRole);
            ps.setString(6, actorName);
            ps.setBoolean(7, seenByCashier);
            ps.executeUpdate();
        }
    }

    private List<Map<String, Object>> cashEvents(Connection con, String type, int limit, boolean unseenOnly) throws Exception {
        String where = "";
        if (!readString(type, "").isEmpty()) where = "WHERE eventType=? ";
        if (unseenOnly) where += where.isEmpty() ? "WHERE seenByCashier=0 " : "AND seenByCashier=0 ";
        String sql = "SELECT TOP " + Math.max(1, limit) + " id,eventType,amount,balanceAfter,note,actorRole,actorName,seenByCashier,createdAt FROM dbo.CashEvents " + where + "ORDER BY id DESC";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            if (!readString(type, "").isEmpty()) ps.setString(1, type);
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    public Map<String, Object> getCupStatus() throws Exception {
        try (Connection con = db.getConnection()) {
            Map<String, Object> status = new LinkedHashMap<>();
            status.put("cupsAvailable", stateValue(con, "cupsAvailable", 0));
            return status;
        }
    }

    public Map<String, Object> updateCupStock(int amount, String mode, String actorName) throws Exception {
        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            int current = stateValueForUpdate(con, "cupsAvailable", 0);
            int next = "adjust".equalsIgnoreCase(readString(mode, "")) ? current + amount : amount;
            if (next < 0 || next > 100000) throw new IllegalArgumentException("Số lượng cốc không hợp lệ.");
            setStateValue(con, "cupsAvailable", next);
            insertSystemLog(con, "admin", actorName, "CUP_STOCK",
                    "Admin cập nhật số cốc từ " + current + " thành " + next + " lúc " + nowLabelVi(),
                    "Admin changed cup stock from " + current + " to " + next + " at " + nowLabelEn(),
                    null);
            con.commit();
            Map<String, Object> status = new LinkedHashMap<>();
            status.put("cupsAvailable", next);
            return status;
        }
    }

    public List<Map<String, Object>> getSystemLogs(String actor) throws Exception {
        String normalized = normalizeActor(actor);
        String where = normalized.isEmpty() ? "" : "WHERE actorRole=? ";
        String sql = "SELECT TOP 200 id,actorRole,actorName,actionType,messageVi,messageEn,refId,createdAt FROM dbo.SystemLogs " + where + "ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            if (!normalized.isEmpty()) ps.setString(1, normalized);
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    public void addSystemLog(String actorRole, String actorName, String actionType, String messageVi, String messageEn, Integer refId) throws Exception {
        try (Connection con = db.getConnection()) {
            insertSystemLog(con, actorRole, actorName, actionType, messageVi, messageEn, refId);
        }
    }

    private int stateValue(Connection con, String key, int fallback) throws Exception {
        ensureState(con, key, fallback);
        try (PreparedStatement ps = con.prepareStatement("SELECT intValue FROM dbo.StoreState WHERE stateKey=?")) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("intValue") : fallback;
            }
        }
    }

    private int stateValueForUpdate(Connection con, String key, int fallback) throws Exception {
        ensureState(con, key, fallback);
        try (PreparedStatement ps = con.prepareStatement("SELECT intValue FROM dbo.StoreState WITH (UPDLOCK, ROWLOCK) WHERE stateKey=?")) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("intValue") : fallback;
            }
        }
    }

    private void setStateValue(Connection con, String key, int value) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.StoreState SET intValue=?, updatedAt=SYSUTCDATETIME() WHERE stateKey=?")) {
            ps.setInt(1, value);
            ps.setString(2, key);
            ps.executeUpdate();
        }
    }

    private void insertSystemLog(Connection con, String actorRole, String actorName, String actionType, String messageVi, String messageEn, Integer refId) throws Exception {
        String role = normalizeActor(actorRole);
        if (role.isEmpty()) role = "system";
        try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.SystemLogs (actorRole,actorName,actionType,messageVi,messageEn,refId) VALUES (?,?,?,?,?,?)")) {
            ps.setString(1, role);
            ps.setString(2, limitLog(actorName));
            ps.setString(3, limitLog(readString(actionType, "ACTION")));
            ps.setString(4, limitLog(messageVi));
            ps.setString(5, limitLog(messageEn));
            if (refId == null || refId <= 0) ps.setNull(6, Types.INTEGER);
            else ps.setInt(6, refId);
            ps.executeUpdate();
        }
    }

    private String normalizeActor(String actor) {
        String value = readString(actor, "").toLowerCase(Locale.ROOT);
        if (Arrays.asList("guest", "admin", "barista", "cashier", "runner", "system").contains(value)) return value;
        return "";
    }

    private String orderCreateLogVi(String actorRole, String tableName, int orderNumber, int totalQuantity) {
        String actor = normalizeActor(actorRole);
        if ("guest".equals(actor)) {
            return tableName + " gọi đơn #" + orderNumber + " (" + totalQuantity + " sản phẩm) lúc " + nowLabelVi();
        }
        return roleNameVi(actor) + " tạo đơn #" + orderNumber + " cho " + tableName + " (" + totalQuantity + " sản phẩm) lúc " + nowLabelVi();
    }

    private String orderCreateLogEn(String actorRole, String tableName, int orderNumber, int totalQuantity) {
        String actor = normalizeActor(actorRole);
        if ("guest".equals(actor)) {
            return tableName + " placed order #" + orderNumber + " (" + totalQuantity + " products) at " + nowLabelEn();
        }
        return roleNameEn(actor) + " created order #" + orderNumber + " for " + tableName + " (" + totalQuantity + " products) at " + nowLabelEn();
    }

    private String statusLogVi(String actorRole, String from, String to, int orderNumber, String tableName) {
        String actor = normalizeActor(actorRole);
        if ("barista".equals(actor) && "Pending".equals(from) && "Preparing".equals(to)) {
            return "Pha chế nhận đơn #" + orderNumber + " của " + tableName + " lúc " + nowLabelVi();
        }
        if ("barista".equals(actor) && "Preparing".equals(from) && "Ready".equals(to)) {
            return "Pha chế hoàn thành đơn #" + orderNumber + " của " + tableName + " lúc " + nowLabelVi();
        }
        if ("runner".equals(actor) && "Ready".equals(from) && "Served".equals(to)) {
            return "Bồi bàn phục vụ đơn #" + orderNumber + " cho " + tableName + " lúc " + nowLabelVi();
        }
        if ("cashier".equals(actor) && "Served".equals(from) && "Paid".equals(to)) {
            return "Thu ngân xác nhận đơn #" + orderNumber + " đã thanh toán lúc " + nowLabelVi();
        }
        return roleNameVi(actor) + " chuyển đơn #" + orderNumber + " từ " + from + " sang " + to + " lúc " + nowLabelVi();
    }

    private String statusLogEn(String actorRole, String from, String to, int orderNumber, String tableName) {
        String actor = normalizeActor(actorRole);
        if ("barista".equals(actor) && "Pending".equals(from) && "Preparing".equals(to)) {
            return "Barista accepted order #" + orderNumber + " at " + tableName + " at " + nowLabelEn();
        }
        if ("barista".equals(actor) && "Preparing".equals(from) && "Ready".equals(to)) {
            return "Barista completed order #" + orderNumber + " at " + tableName + " at " + nowLabelEn();
        }
        if ("runner".equals(actor) && "Ready".equals(from) && "Served".equals(to)) {
            return "Waiter served order #" + orderNumber + " to " + tableName + " at " + nowLabelEn();
        }
        if ("cashier".equals(actor) && "Served".equals(from) && "Paid".equals(to)) {
            return "Cashier marked order #" + orderNumber + " as paid at " + nowLabelEn();
        }
        return roleNameEn(actor) + " moved order #" + orderNumber + " from " + from + " to " + to + " at " + nowLabelEn();
    }

    private String roleNameVi(String role) {
        if ("guest".equals(role)) return "Khách";
        if ("admin".equals(role)) return "Admin";
        if ("barista".equals(role)) return "Pha chế";
        if ("cashier".equals(role)) return "Thu ngân";
        if ("runner".equals(role)) return "Bồi bàn";
        return "Hệ thống";
    }

    private String roleNameEn(String role) {
        if ("guest".equals(role)) return "Guest";
        if ("admin".equals(role)) return "Admin";
        if ("barista".equals(role)) return "Barista";
        if ("cashier".equals(role)) return "Cashier";
        if ("runner".equals(role)) return "Waiter";
        return "System";
    }

    private String nowLabelVi() {
        return java.time.LocalDateTime.now(APP_ZONE).format(java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy"));
    }

    private String nowLabelEn() {
        return java.time.LocalDateTime.now(APP_ZONE).format(java.time.format.DateTimeFormatter.ofPattern("HH:mm MM/dd/yyyy"));
    }

    private String limitLog(String text) {
        String clean = readString(text, "");
        return clean.length() > 380 ? clean.substring(0, 380) : clean;
    }

    public Map<String, Object> getOrderById(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, orderNumber, tableName, customerPhone, status, total, note, createdAt, invoicePrinted FROM dbo.Orders WHERE id=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String, Object> order = row(rs);
                order.put("items", getOrderItems(id));
                return order;
            }
        }
    }

    public Map<String, Object> getOrderInvoice(int id) throws Exception {
        Map<String, Object> order = getOrderById(id);
        if (order == null) return null;
        order.remove("customerPhone");
        return order;
    }

    public Map<String, Object> markInvoicePrinted(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(
                "UPDATE dbo.Orders SET invoicePrinted=1 WHERE id=? AND status IN ('Ready','Served')")) {
            ps.setInt(1, id);
            int updated = ps.executeUpdate();
            if (updated == 0) {
                Map<String, Object> order = getOrderById(id);
                if (order == null) throw new IllegalArgumentException("Không tìm thấy đơn hàng.");
                throw new IllegalArgumentException("Chỉ đánh dấu đã in cho đơn Ready hoặc Served.");
            }
        }
        return getOrderInvoice(id);
    }

    private List<Map<String, Object>> getOrderItems(int orderId) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, menuItemId, itemName, itemSize, quantity, price FROM dbo.OrderItems WHERE orderId=? ORDER BY id")) {
            ps.setInt(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    public Map<String, Object> getDashboard() throws Exception {
        return getDashboard(null, null);
    }

    public Map<String, Object> getDashboard(String customStartRaw, String customEndRaw) throws Exception {
        Map<String, Object> stats = new LinkedHashMap<>();
        LocalDate customStart = readDate(customStartRaw);
        LocalDate customEnd = readDate(customEndRaw);
        if (customStart != null && customEnd != null && customEnd.isBefore(customStart)) {
            LocalDate tmp = customStart;
            customStart = customEnd;
            customEnd = tmp;
        }
        LocalDate today = appToday();
        LocalDate tomorrow = today.plusDays(1);
        LocalDate monthStart = today.withDayOfMonth(1);
        LocalDate yearStart = today.withDayOfYear(1);
        try (Connection con = db.getConnection()) {
            int pending = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Pending'");
            int preparing = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Preparing'");
            int ready = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Ready'");
            int served = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Served'");
            int paid = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Paid'");
            int cleared = scalar(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Cleared'");
            stats.put("menuCount", scalar(con, "SELECT COUNT(*) FROM dbo.MenuItems WHERE active=1"));
            stats.put("orderCount", pending + preparing + ready + served + paid + cleared);
            stats.put("pendingOrderCount", pending);
            stats.put("preparingOrderCount", preparing);
            stats.put("readyOrderCount", ready);
            stats.put("unpaidOrderCount", served);
            stats.put("servedOrderCount", paid + cleared);
            stats.put("unclearedOrderCount", paid);
            stats.put("clearedOrderCount", cleared);
            stats.put("activeOrderCount", pending + preparing + ready + served + paid);
            stats.put("revenue", scalar(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Paid','Cleared')"));
            stats.put("revenueToday", scalarBetween(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ?", today, tomorrow));
            stats.put("revenueMonth", scalarBetween(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ?", monthStart, tomorrow));
            stats.put("revenueYear", scalarBetween(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ?", yearStart, tomorrow));
            stats.put("unpaidRevenue", scalar(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status = 'Served'"));
            stats.put("openRevenue", scalar(con, "SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Pending','Preparing','Ready')"));
            stats.put("soldItemCount", scalar(con, "SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared')"));
            stats.put("soldItemToday", scalarBetween(con, "SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') AND o.createdAt >= ? AND o.createdAt < ?", today, tomorrow));
            stats.put("soldItemMonth", scalarBetween(con, "SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') AND o.createdAt >= ? AND o.createdAt < ?", monthStart, tomorrow));
            stats.put("soldItemYear", scalarBetween(con, "SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') AND o.createdAt >= ? AND o.createdAt < ?", yearStart, tomorrow));
            stats.put("bestSeller", firstRow(con, "SELECT TOP 1 oi.itemName, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') GROUP BY oi.itemName ORDER BY SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC"));
            stats.put("topProducts", queryRows(con, "SELECT TOP 8 oi.itemName, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') GROUP BY oi.itemName ORDER BY SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC"));
            stats.put("topProductsByRange", getTopProductsByRangeMap(con, customStart, customEnd));
            stats.put("rangeDetails", getRangeDetailsMap(con, customStart, customEnd));
            stats.put("revenueSeries", getRevenueSeriesMap(con, customStart, customEnd));
            stats.put("lowStockItems", getLowStockIngredients(con));
            stats.put("today", today.toString());
            if (customStart != null && customEnd != null) {
                stats.put("customStart", customStart.toString());
                stats.put("customEnd", customEnd.toString());
            }
        }
        return stats;
    }

    private int scalar(String sql) throws Exception {
        try (Connection con = db.getConnection(); Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getInt(1);
        }
    }

    private int scalar(Connection con, String sql) throws Exception {
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getInt(1);
        }
    }

    private int scalarBetween(Connection con, String sql, LocalDate start, LocalDate endExclusive) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private Map<String, Object> firstRow(String sql) throws Exception {
        List<Map<String, Object>> list = queryRows(sql);
        return list.isEmpty() ? new LinkedHashMap<>() : list.get(0);
    }

    private Map<String, Object> firstRow(Connection con, String sql) throws Exception {
        List<Map<String, Object>> list = queryRows(con, sql);
        return list.isEmpty() ? new LinkedHashMap<>() : list.get(0);
    }

    private List<Map<String, Object>> queryRows(String sql) throws Exception {
        try (Connection con = db.getConnection(); Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            return rows(rs);
        }
    }

    private List<Map<String, Object>> queryRows(Connection con, String sql) throws Exception {
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            return rows(rs);
        }
    }

    private Map<String, Object> getRevenueSeriesMap(Connection con, LocalDate customStart, LocalDate customEnd) throws Exception {
        LocalDate today = appToday();
        LocalDate tomorrow = today.plusDays(1);
        YearMonth firstMonth = YearMonth.from(today.minusMonths(11));
        YearMonth nextMonth = YearMonth.from(today).plusMonths(1);
        YearMonth allFirstMonth = firstPaidMonth(con, firstMonth);

        Map<String, Object> series = new LinkedHashMap<>();
        series.put("day", revenueByHour(con, today, tomorrow));
        series.put("week", revenueByDay(con, today.minusDays(6), tomorrow));
        series.put("month", revenueByDay(con, today.minusDays(29), tomorrow));
        series.put("year", revenueByMonth(con, firstMonth, nextMonth));
        series.put("all", revenueByMonth(con, allFirstMonth, nextMonth));
        if (customStart != null && customEnd != null) {
            series.put("custom", revenueCustom(con, customStart, customEnd.plusDays(1)));
        }
        return series;
    }

    private Map<String, Object> getTopProductsByRangeMap(Connection con, LocalDate customStart, LocalDate customEnd) throws Exception {
        LocalDate today = appToday();
        LocalDate tomorrow = today.plusDays(1);
        YearMonth firstMonth = YearMonth.from(today.minusMonths(11));
        YearMonth nextMonth = YearMonth.from(today).plusMonths(1);
        YearMonth allFirstMonth = firstPaidMonth(con, firstMonth);

        Map<String, Object> products = new LinkedHashMap<>();
        products.put("day", topProductsBetween(con, today, tomorrow, 8));
        products.put("week", topProductsBetween(con, today.minusDays(6), tomorrow, 8));
        products.put("month", topProductsBetween(con, today.minusDays(29), tomorrow, 8));
        products.put("year", topProductsBetween(con, firstMonth.atDay(1), nextMonth.atDay(1), 8));
        products.put("all", topProductsBetween(con, allFirstMonth.atDay(1), nextMonth.atDay(1), 8));
        if (customStart != null && customEnd != null) {
            products.put("custom", topProductsBetween(con, customStart, customEnd.plusDays(1), 8));
        }
        return products;
    }

    private Map<String, Object> getRangeDetailsMap(Connection con, LocalDate customStart, LocalDate customEnd) throws Exception {
        LocalDate today = appToday();
        LocalDate tomorrow = today.plusDays(1);
        YearMonth firstMonth = YearMonth.from(today.minusMonths(11));
        YearMonth nextMonth = YearMonth.from(today).plusMonths(1);
        YearMonth allFirstMonth = firstPaidMonth(con, firstMonth);

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("day", rangeDetailBetween(con, today, tomorrow));
        details.put("week", rangeDetailBetween(con, today.minusDays(6), tomorrow));
        details.put("month", rangeDetailBetween(con, today.minusDays(29), tomorrow));
        details.put("year", rangeDetailBetween(con, firstMonth.atDay(1), nextMonth.atDay(1)));
        details.put("all", rangeDetailBetween(con, allFirstMonth.atDay(1), nextMonth.atDay(1)));
        if (customStart != null && customEnd != null) {
            details.put("custom", rangeDetailBetween(con, customStart, customEnd.plusDays(1)));
        }
        return details;
    }

    private Map<String, Object> rangeDetailBetween(Connection con, LocalDate start, LocalDate endExclusive) throws Exception {
        Map<String, Object> detail = new LinkedHashMap<>();
        String orderSql = "SELECT COUNT(*) paidOrders, ISNULL(SUM(total),0) revenue FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ?";
        try (PreparedStatement ps = con.prepareStatement(orderSql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    detail.put("paidOrders", rs.getInt("paidOrders"));
                    detail.put("revenue", rs.getInt("revenue"));
                }
            }
        }
        String itemSql = "SELECT ISNULL(SUM(oi.quantity),0) soldProducts FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') AND o.createdAt >= ? AND o.createdAt < ?";
        try (PreparedStatement ps = con.prepareStatement(itemSql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) detail.put("soldProducts", rs.getInt("soldProducts"));
            }
        }
        detail.putIfAbsent("paidOrders", 0);
        detail.putIfAbsent("revenue", 0);
        detail.putIfAbsent("soldProducts", 0);
        return detail;
    }

    private List<Map<String, Object>> revenueCustom(Connection con, LocalDate start, LocalDate endExclusive) throws Exception {
        long days = ChronoUnit.DAYS.between(start, endExclusive);
        if (days <= 1) return revenueByHour(con, start, endExclusive);
        if (days <= 120) return revenueByDay(con, start, endExclusive);
        return revenueByMonth(con, YearMonth.from(start), YearMonth.from(endExclusive.minusDays(1)).plusMonths(1));
    }

    private YearMonth firstPaidMonth(Connection con, YearMonth fallback) throws Exception {
        String sql = "SELECT MIN(CONVERT(date, createdAt)) firstDate FROM dbo.Orders WHERE status IN ('Paid','Cleared')";
        try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) {
                LocalDate date = readDate(rs.getObject("firstDate"));
                if (date != null) return YearMonth.from(date);
            }
        }
        return fallback;
    }

    private List<Map<String, Object>> revenueByHour(Connection con, LocalDate start, LocalDate endExclusive) throws Exception {
        Map<String, Integer> values = new LinkedHashMap<>();
        for (int hour = 0; hour < 24; hour++) {
            values.put(String.format(Locale.ROOT, "%02d:00", hour), 0);
        }
        String sql = "SELECT DATEPART(hour, createdAt) saleHour, ISNULL(SUM(total),0) revenue "
                + "FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ? "
                + "GROUP BY DATEPART(hour, createdAt)";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    values.put(String.format(Locale.ROOT, "%02d:00", rs.getInt("saleHour")), rs.getInt("revenue"));
                }
            }
        }
        return seriesRows(values);
    }

    private List<Map<String, Object>> revenueByDay(Connection con, LocalDate start, LocalDate endExclusive) throws Exception {
        Map<String, Integer> values = new LinkedHashMap<>();
        for (LocalDate day = start; day.isBefore(endExclusive); day = day.plusDays(1)) {
            values.put(day.toString(), 0);
        }
        String sql = "SELECT CONVERT(date, createdAt) saleDate, ISNULL(SUM(total),0) revenue "
                + "FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ? "
                + "GROUP BY CONVERT(date, createdAt)";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LocalDate date = rs.getDate("saleDate").toLocalDate();
                    if (values.containsKey(date.toString())) values.put(date.toString(), rs.getInt("revenue"));
                }
            }
        }
        return seriesRows(values);
    }

    private List<Map<String, Object>> revenueByMonth(Connection con, YearMonth start, YearMonth endExclusive) throws Exception {
        Map<String, Integer> values = new LinkedHashMap<>();
        for (YearMonth month = start; month.isBefore(endExclusive); month = month.plusMonths(1)) {
            values.put(month.toString(), 0);
        }
        String sql = "SELECT CONVERT(char(7), createdAt, 120) saleMonth, ISNULL(SUM(total),0) revenue "
                + "FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ? "
                + "GROUP BY CONVERT(char(7), createdAt, 120)";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atDay(1).atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atDay(1).atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String month = rs.getString("saleMonth");
                    if (values.containsKey(month)) values.put(month, rs.getInt("revenue"));
                }
            }
        }
        return seriesRows(values);
    }

    private List<Map<String, Object>> topProductsBetween(Connection con, LocalDate start, LocalDate endExclusive, int limit) throws Exception {
        String sql = "SELECT TOP " + Math.max(1, limit) + " oi.itemName, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue "
                + "FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId "
                + "WHERE o.status IN ('Paid','Cleared') AND o.createdAt >= ? AND o.createdAt < ? "
                + "GROUP BY oi.itemName ORDER BY SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setTimestamp(1, Timestamp.valueOf(start.atStartOfDay()));
            ps.setTimestamp(2, Timestamp.valueOf(endExclusive.atStartOfDay()));
            try (ResultSet rs = ps.executeQuery()) {
                return rows(rs);
            }
        }
    }

    private List<Map<String, Object>> seriesRows(Map<String, Integer> values) {
        List<Map<String, Object>> series = new ArrayList<>();
        for (Map.Entry<String, Integer> entry : values.entrySet()) {
            Map<String, Object> point = new LinkedHashMap<>();
            point.put("label", entry.getKey());
            point.put("revenue", entry.getValue());
            series.add(point);
        }
        return series;
    }

    private String weekKey(LocalDate date) {
        return date.minusDays(date.getDayOfWeek().getValue() - 1L).toString();
    }

    private LocalDate readDate(Object value) {
        if (value instanceof java.sql.Date) return ((java.sql.Date) value).toLocalDate();
        if (value == null) return null;
        try {
            return LocalDate.parse(String.valueOf(value).substring(0, 10));
        } catch (Exception e) {
            return null;
        }
    }

    private List<Map<String, Object>> rows(ResultSet rs) throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        while (rs.next()) list.add(row(rs));
        return list;
    }

    private Map<String, Object> row(ResultSet rs) throws Exception {
        Map<String, Object> map = new LinkedHashMap<>();
        ResultSetMetaData md = rs.getMetaData();
        for (int i = 1; i <= md.getColumnCount(); i++) {
            Object val = rs.getObject(i);
            if (val instanceof java.sql.Timestamp) val = val.toString();
            map.put(md.getColumnLabel(i), val);
        }
        return map;
    }

    private String readString(Object value, String fallback) {
        return value == null ? fallback : String.valueOf(value).trim();
    }

    private int readInt(Object value, int fallback) {
        if (value instanceof Number) return ((Number) value).intValue();
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (Exception e) {
            return fallback;
        }
    }

    private List<Integer> cleanIds(List<Integer> ids) {
        List<Integer> clean = new ArrayList<>();
        if (ids == null) return clean;
        for (Integer id : ids) {
            if (id != null && id > 0 && !clean.contains(id)) clean.add(id);
            if (clean.size() >= 50) break;
        }
        return clean;
    }

    private String placeholders(int count) {
        StringJoiner joiner = new StringJoiner(",");
        for (int i = 0; i < count; i++) joiner.add("?");
        return joiner.toString();
    }

    private void bindIds(PreparedStatement ps, List<Integer> ids) throws Exception {
        for (int i = 0; i < ids.size(); i++) {
            ps.setInt(i + 1, ids.get(i));
        }
    }

    private String limitNote(String note) {
        String clean = readString(note, "");
        return clean.length() > 255 ? clean.substring(0, 255) : clean;
    }

    private String normalizeSize(Map<String, Object> menu, String size) {
        List<Map<String, Object>> sizes = menuSizes(menu);
        if (sizes.isEmpty()) return "";
        String normalized = size == null ? "" : size.trim().toUpperCase(Locale.ROOT);
        for (Map<String, Object> row : sizes) {
            String name = readString(row.get("sizeName"), "").toUpperCase(Locale.ROOT);
            if (name.equals(normalized)) return name;
        }
        return readString(sizes.get(0).get("sizeName"), "S").toUpperCase(Locale.ROOT);
    }

    private boolean isDrink(Map<String, Object> menu) {
        return isDrinkCategory(readString(menu.get("category"), ""));
    }

    private boolean isDrinkCategory(String category) {
        String folded = fold(category);
        return !(folded.equals("food") || folded.equals("pastry") || folded.contains("banh"));
    }

    private int priceForSize(Map<String, Object> menu, String size) {
        int base = readInt(menu.get("price"), 0);
        for (Map<String, Object> row : menuSizes(menu)) {
            if (readString(row.get("sizeName"), "").equalsIgnoreCase(readString(size, ""))) {
                return base + readInt(row.get("extraPrice"), 0);
            }
        }
        return base;
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> menuSizes(Map<String, Object> menu) {
        Object sizes = menu.get("sizes");
        if (sizes instanceof List<?>) return (List<Map<String, Object>>) sizes;
        return new ArrayList<>();
    }

    private boolean readBoolean(Object value, boolean fallback) {
        if (value instanceof Boolean) return (Boolean) value;
        if (value instanceof Number) return ((Number) value).intValue() != 0;
        if (value == null) return fallback;
        String text = String.valueOf(value).trim();
        if ("1".equals(text) || "true".equalsIgnoreCase(text)) return true;
        if ("0".equals(text) || "false".equalsIgnoreCase(text)) return false;
        return Boolean.parseBoolean(text);
    }
}
