package service;

import context.DBContext;

import java.sql.*;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.temporal.ChronoUnit;
import java.util.*;

public class LiteService {
    private static final LiteService INSTANCE = new LiteService();
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
            st.execute("IF OBJECT_ID('dbo.OrderItems','U') IS NULL CREATE TABLE dbo.OrderItems (id INT IDENTITY PRIMARY KEY, orderId INT NOT NULL, menuItemId INT NOT NULL, itemName NVARCHAR(120) NOT NULL, itemSize VARCHAR(20) NULL, quantity INT NOT NULL, price INT NOT NULL, FOREIGN KEY(orderId) REFERENCES dbo.Orders(id))");
            st.execute("IF COL_LENGTH('dbo.OrderItems','itemSize') IS NULL ALTER TABLE dbo.OrderItems ADD itemSize VARCHAR(20) NULL");
            st.execute("ALTER TABLE dbo.OrderItems ALTER COLUMN itemSize VARCHAR(20) NULL");
            st.execute("IF OBJECT_ID('dbo.CashEvents','U') IS NULL CREATE TABLE dbo.CashEvents (id INT IDENTITY PRIMARY KEY, eventType VARCHAR(30) NOT NULL, amount INT NOT NULL, balanceAfter INT NOT NULL, note NVARCHAR(255) NULL, actorRole VARCHAR(20) NULL, actorName NVARCHAR(120) NULL, seenByCashier BIT NOT NULL DEFAULT 1, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF COL_LENGTH('dbo.CashEvents','seenByCashier') IS NULL ALTER TABLE dbo.CashEvents ADD seenByCashier BIT NOT NULL DEFAULT 1");
            st.execute("IF OBJECT_ID('dbo.StoreState','U') IS NULL CREATE TABLE dbo.StoreState (stateKey VARCHAR(50) PRIMARY KEY, intValue INT NOT NULL, updatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
            st.execute("IF OBJECT_ID('dbo.SystemLogs','U') IS NULL CREATE TABLE dbo.SystemLogs (id INT IDENTITY PRIMARY KEY, actorRole VARCHAR(20) NOT NULL, actorName NVARCHAR(120) NULL, actionType VARCHAR(40) NOT NULL, messageVi NVARCHAR(400) NOT NULL, messageEn NVARCHAR(400) NOT NULL, refId INT NULL, createdAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME())");
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
        boolean enoughHistory = count(con, "SELECT COUNT(*) FROM dbo.Orders WHERE status='Cleared' AND createdAt >= DATEADD(day, -370, CONVERT(date, SYSUTCDATETIME()))") >= 160;

        List<Map<String, Object>> menu = queryRows(con, "SELECT id, nameVi, category, price FROM dbo.MenuItems WHERE active=1 ORDER BY id");
        for (Map<String, Object> item : menu) {
            item.put("sizes", getMenuSizes(con, readInt(item.get("id"), 0)));
        }
        List<Map<String, Object>> tables = queryRows(con, "SELECT name FROM dbo.Tables WHERE active=1 AND floorNo IS NOT NULL ORDER BY floorNo, tableNo");
        if (menu.isEmpty() || tables.isEmpty()) return;

        Random random = new Random(205063);
        if (!enoughHistory) {
            LocalDate start = LocalDate.now().minusDays(360);
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
        int orderId = insertSeedOrder(con, tableName, LocalDate.now() + "T" + String.format(Locale.ROOT, "%02d:%02d:00", 9 + random.nextInt(8), random.nextInt(60)), status);
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
            for (Map<String, Object> item : menu) {
                item.put("sizes", getMenuSizes(con, readInt(item.get("id"), 0)));
            }
            return menu;
        }
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
            con.commit();
        }
        return getMenuItem(id);
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
                return item;
            }
        }
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
        String sql = "SELECT id, orderNumber, tableName, customerPhone, status, total, note, createdAt FROM dbo.Orders "
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
            int orderId;
            int orderNumber;
            String tableName;
            String findSql = "SELECT TOP 1 o.id, o.orderNumber, t.name tableName "
                    + "FROM dbo.Orders o JOIN dbo.Tables t ON t.name=o.tableName "
                    + "WHERE t.id=? AND o.status='Paid' ORDER BY o.id DESC";
            try (PreparedStatement ps = con.prepareStatement(findSql)) {
                ps.setInt(1, tableId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("Bàn này không có đơn chờ dọn.");
                    }
                    orderId = rs.getInt("id");
                    orderNumber = rs.getInt("orderNumber");
                    tableName = rs.getString("tableName");
                }
            }
            try (PreparedStatement ps = con.prepareStatement("UPDATE dbo.Orders SET status='Cleared' WHERE id=? AND status='Paid'")) {
                ps.setInt(1, orderId);
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("Bàn này vừa được cập nhật bởi thiết bị khác.");
                }
            }
            insertSystemLog(con, actorRole, actorName, "TABLE_CLEAR",
                    "Bồi bàn dọn xong " + tableName + " cho đơn #" + orderNumber + " lúc " + nowLabelVi(),
                    "Waiter cleared " + tableName + " for order #" + orderNumber + " at " + nowLabelEn(),
                    orderId);
            con.commit();
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("message", "Table ready");
            result.put("tableId", tableId);
            result.put("tableName", tableName);
            result.put("busy", false);
            result.put("status", "Available");
            result.put("orderId", orderId);
            result.put("orderNumber", orderNumber);
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
        String tableName = readString(data.get("tableName"), "Bàn 1");
        String phone = readString(data.get("customerPhone"), "");
        String note = limitNote(readString(data.get("note"), ""));
        List<?> items = data.get("items") instanceof List<?> ? (List<?>) data.get("items") : Collections.emptyList();
        if (items.isEmpty()) throw new IllegalArgumentException("Đơn hàng chưa có món.");

        try (Connection con = db.getConnection()) {
            con.setAutoCommit(false);
            int orderId;
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO dbo.Orders (tableName,customerPhone,note,total) VALUES (?,?,?,0)", Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, tableName);
                ps.setString(2, phone.isEmpty() ? null : phone);
                ps.setString(3, note);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    keys.next();
                    orderId = keys.getInt(1);
                }
            }

            int total = 0;
            int totalQuantity = 0;
            for (Object raw : items) {
                if (!(raw instanceof Map<?, ?>)) continue;
                Map<?, ?> item = (Map<?, ?>) raw;
                int menuId = readInt(item.get("menuItemId"), 0);
                int quantity = Math.max(1, readInt(item.get("quantity"), 1));
                Map<String, Object> menu = getMenuItem(menuId);
                if (menu == null) continue;
                String size = normalizeSize(menu, readString(item.get("size"), ""));
                int price = priceForSize(menu, size);
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
            insertSystemLog(con, "guest", phone.isEmpty() ? "Khách" : phone, "ORDER_CREATE",
                    tableName + " gọi đơn #" + orderNumber + " (" + totalQuantity + " sản phẩm) lúc " + nowLabelVi(),
                    tableName + " placed order #" + orderNumber + " (" + totalQuantity + " products) at " + nowLabelEn(),
                    orderId);
            con.commit();
            return getOrderById(orderId);
        }
    }

    public List<Map<String, Object>> getOrders() throws Exception {
        return getOrders("");
    }

    public List<Map<String, Object>> getOrders(String role) throws Exception {
        return getOrders(role, null);
    }

    public List<Map<String, Object>> getOrders(String role, List<Integer> cashierSessionPaidIds) throws Exception {
        String sql = "SELECT id, orderNumber, tableName, customerPhone, status, total, note, createdAt FROM dbo.Orders ";
        if ("barista".equals(role)) {
            sql += "WHERE status IN ('Pending','Preparing','Ready') ";
        } else if ("cashier".equals(role)) {
            String sessionPaid = paidIdList(cashierSessionPaidIds);
            sql += sessionPaid.isEmpty()
                    ? "WHERE status='Served' "
                    : "WHERE status='Served' OR id IN (" + sessionPaid + ") ";
        } else if ("runner".equals(role)) {
            sql += "WHERE status IN ('Ready','Paid') ";
        }
        sql += "ORDER BY id DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            List<Map<String, Object>> list = rows(rs);
            for (Map<String, Object> order : list) {
                order.put("items", getOrderItems(readInt(order.get("id"), 0)));
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
            con.commit();
        }
        return getOrderById(id);
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
        return java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy"));
    }

    private String nowLabelEn() {
        return java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm MM/dd/yyyy"));
    }

    private String limitLog(String text) {
        String clean = readString(text, "");
        return clean.length() > 380 ? clean.substring(0, 380) : clean;
    }

    public Map<String, Object> getOrderById(int id) throws Exception {
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement("SELECT id, orderNumber, tableName, customerPhone, status, total, note, createdAt FROM dbo.Orders WHERE id=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Map<String, Object> order = row(rs);
                order.put("items", getOrderItems(id));
                return order;
            }
        }
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
        int pending = scalar("SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Pending'");
        int preparing = scalar("SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Preparing'");
        int ready = scalar("SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Ready'");
        int served = scalar("SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Served'");
        int paid = scalar("SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Paid'");
        int cleared = scalar("SELECT COUNT(*) FROM dbo.Orders WHERE status = 'Cleared'");
        stats.put("menuCount", scalar("SELECT COUNT(*) FROM dbo.MenuItems WHERE active=1"));
        stats.put("orderCount", pending + preparing + ready + served + paid + cleared);
        stats.put("pendingOrderCount", pending);
        stats.put("preparingOrderCount", preparing);
        stats.put("readyOrderCount", ready);
        stats.put("unpaidOrderCount", served);
        stats.put("servedOrderCount", paid + cleared);
        stats.put("unclearedOrderCount", paid);
        stats.put("clearedOrderCount", cleared);
        stats.put("activeOrderCount", pending + preparing + ready + served + paid);
        stats.put("revenue", scalar("SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Paid','Cleared')"));
        stats.put("revenueToday", scalar("SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND CONVERT(date, createdAt)=CONVERT(date, SYSUTCDATETIME())"));
        stats.put("revenueMonth", scalar("SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= DATEFROMPARTS(YEAR(SYSUTCDATETIME()), MONTH(SYSUTCDATETIME()), 1)"));
        stats.put("revenueYear", scalar("SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= DATEFROMPARTS(YEAR(SYSUTCDATETIME()), 1, 1)"));
        stats.put("unpaidRevenue", scalar("SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status = 'Served'"));
        stats.put("openRevenue", scalar("SELECT ISNULL(SUM(total),0) FROM dbo.Orders WHERE status IN ('Pending','Preparing','Ready')"));
        stats.put("soldItemCount", scalar("SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared')"));
        stats.put("soldItemToday", scalar("SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') AND CONVERT(date, o.createdAt)=CONVERT(date, SYSUTCDATETIME())"));
        stats.put("soldItemMonth", scalar("SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') AND o.createdAt >= DATEFROMPARTS(YEAR(SYSUTCDATETIME()), MONTH(SYSUTCDATETIME()), 1)"));
        stats.put("soldItemYear", scalar("SELECT ISNULL(SUM(oi.quantity),0) FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') AND o.createdAt >= DATEFROMPARTS(YEAR(SYSUTCDATETIME()), 1, 1)"));
        stats.put("bestSeller", firstRow("SELECT TOP 1 oi.itemName, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') GROUP BY oi.itemName ORDER BY SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC"));
        stats.put("topProducts", queryRows("SELECT TOP 8 oi.itemName, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId WHERE o.status IN ('Paid','Cleared') GROUP BY oi.itemName ORDER BY SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC"));
        stats.put("topProductsByRange", getTopProductsByRangeMap(customStart, customEnd));
        stats.put("rangeDetails", getRangeDetailsMap(customStart, customEnd));
        stats.put("revenueSeries", getRevenueSeriesMap(customStart, customEnd));
        stats.put("today", LocalDate.now().toString());
        if (customStart != null && customEnd != null) {
            stats.put("customStart", customStart.toString());
            stats.put("customEnd", customEnd.toString());
        }
        return stats;
    }

    private int scalar(String sql) throws Exception {
        try (Connection con = db.getConnection(); Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            rs.next();
            return rs.getInt(1);
        }
    }

    private Map<String, Object> firstRow(String sql) throws Exception {
        List<Map<String, Object>> list = queryRows(sql);
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

    private Map<String, Object> getRevenueSeriesMap(LocalDate customStart, LocalDate customEnd) throws Exception {
        LocalDate today = LocalDate.now();
        LocalDate tomorrow = today.plusDays(1);
        YearMonth firstMonth = YearMonth.from(today.minusMonths(11));
        YearMonth nextMonth = YearMonth.from(today).plusMonths(1);
        YearMonth allFirstMonth = firstPaidMonth(firstMonth);

        Map<String, Object> series = new LinkedHashMap<>();
        series.put("day", revenueByHour(today, tomorrow));
        series.put("week", revenueByDay(today.minusDays(6), tomorrow));
        series.put("month", revenueByDay(today.minusDays(29), tomorrow));
        series.put("year", revenueByMonth(firstMonth, nextMonth));
        series.put("all", revenueByMonth(allFirstMonth, nextMonth));
        if (customStart != null && customEnd != null) {
            series.put("custom", revenueCustom(customStart, customEnd.plusDays(1)));
        }
        return series;
    }

    private Map<String, Object> getTopProductsByRangeMap(LocalDate customStart, LocalDate customEnd) throws Exception {
        LocalDate today = LocalDate.now();
        LocalDate tomorrow = today.plusDays(1);
        YearMonth firstMonth = YearMonth.from(today.minusMonths(11));
        YearMonth nextMonth = YearMonth.from(today).plusMonths(1);
        YearMonth allFirstMonth = firstPaidMonth(firstMonth);

        Map<String, Object> products = new LinkedHashMap<>();
        products.put("day", topProductsBetween(today, tomorrow, 8));
        products.put("week", topProductsBetween(today.minusDays(6), tomorrow, 8));
        products.put("month", topProductsBetween(today.minusDays(29), tomorrow, 8));
        products.put("year", topProductsBetween(firstMonth.atDay(1), nextMonth.atDay(1), 8));
        products.put("all", topProductsBetween(allFirstMonth.atDay(1), nextMonth.atDay(1), 8));
        if (customStart != null && customEnd != null) {
            products.put("custom", topProductsBetween(customStart, customEnd.plusDays(1), 8));
        }
        return products;
    }

    private Map<String, Object> getRangeDetailsMap(LocalDate customStart, LocalDate customEnd) throws Exception {
        LocalDate today = LocalDate.now();
        LocalDate tomorrow = today.plusDays(1);
        YearMonth firstMonth = YearMonth.from(today.minusMonths(11));
        YearMonth nextMonth = YearMonth.from(today).plusMonths(1);
        YearMonth allFirstMonth = firstPaidMonth(firstMonth);

        Map<String, Object> details = new LinkedHashMap<>();
        details.put("day", rangeDetailBetween(today, tomorrow));
        details.put("week", rangeDetailBetween(today.minusDays(6), tomorrow));
        details.put("month", rangeDetailBetween(today.minusDays(29), tomorrow));
        details.put("year", rangeDetailBetween(firstMonth.atDay(1), nextMonth.atDay(1)));
        details.put("all", rangeDetailBetween(allFirstMonth.atDay(1), nextMonth.atDay(1)));
        if (customStart != null && customEnd != null) {
            details.put("custom", rangeDetailBetween(customStart, customEnd.plusDays(1)));
        }
        return details;
    }

    private Map<String, Object> rangeDetailBetween(LocalDate start, LocalDate endExclusive) throws Exception {
        Map<String, Object> detail = new LinkedHashMap<>();
        String orderSql = "SELECT COUNT(*) paidOrders, ISNULL(SUM(total),0) revenue FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ?";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(orderSql)) {
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
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(itemSql)) {
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

    private List<Map<String, Object>> revenueCustom(LocalDate start, LocalDate endExclusive) throws Exception {
        long days = ChronoUnit.DAYS.between(start, endExclusive);
        if (days <= 1) return revenueByHour(start, endExclusive);
        if (days <= 120) return revenueByDay(start, endExclusive);
        return revenueByMonth(YearMonth.from(start), YearMonth.from(endExclusive.minusDays(1)).plusMonths(1));
    }

    private YearMonth firstPaidMonth(YearMonth fallback) throws Exception {
        String sql = "SELECT MIN(CONVERT(date, createdAt)) firstDate FROM dbo.Orders WHERE status IN ('Paid','Cleared')";
        try (Connection con = db.getConnection(); Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) {
                LocalDate date = readDate(rs.getObject("firstDate"));
                if (date != null) return YearMonth.from(date);
            }
        }
        return fallback;
    }

    private List<Map<String, Object>> revenueByHour(LocalDate start, LocalDate endExclusive) throws Exception {
        Map<String, Integer> values = new LinkedHashMap<>();
        for (int hour = 0; hour < 24; hour++) {
            values.put(String.format(Locale.ROOT, "%02d:00", hour), 0);
        }
        String sql = "SELECT DATEPART(hour, createdAt) saleHour, ISNULL(SUM(total),0) revenue "
                + "FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ? "
                + "GROUP BY DATEPART(hour, createdAt)";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
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

    private List<Map<String, Object>> revenueByDay(LocalDate start, LocalDate endExclusive) throws Exception {
        Map<String, Integer> values = new LinkedHashMap<>();
        for (LocalDate day = start; day.isBefore(endExclusive); day = day.plusDays(1)) {
            values.put(day.toString(), 0);
        }
        String sql = "SELECT CONVERT(date, createdAt) saleDate, ISNULL(SUM(total),0) revenue "
                + "FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ? "
                + "GROUP BY CONVERT(date, createdAt)";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
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

    private List<Map<String, Object>> revenueByMonth(YearMonth start, YearMonth endExclusive) throws Exception {
        Map<String, Integer> values = new LinkedHashMap<>();
        for (YearMonth month = start; month.isBefore(endExclusive); month = month.plusMonths(1)) {
            values.put(month.toString(), 0);
        }
        String sql = "SELECT CONVERT(char(7), createdAt, 120) saleMonth, ISNULL(SUM(total),0) revenue "
                + "FROM dbo.Orders WHERE status IN ('Paid','Cleared') AND createdAt >= ? AND createdAt < ? "
                + "GROUP BY CONVERT(char(7), createdAt, 120)";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
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

    private List<Map<String, Object>> topProductsBetween(LocalDate start, LocalDate endExclusive, int limit) throws Exception {
        String sql = "SELECT TOP " + Math.max(1, limit) + " oi.itemName, SUM(oi.quantity) quantity, SUM(oi.price * oi.quantity) revenue "
                + "FROM dbo.OrderItems oi JOIN dbo.Orders o ON o.id=oi.orderId "
                + "WHERE o.status IN ('Paid','Cleared') AND o.createdAt >= ? AND o.createdAt < ? "
                + "GROUP BY oi.itemName ORDER BY SUM(oi.quantity) DESC, SUM(oi.price * oi.quantity) DESC";
        try (Connection con = db.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
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
        if (value == null) return fallback;
        return Boolean.parseBoolean(String.valueOf(value));
    }
}
