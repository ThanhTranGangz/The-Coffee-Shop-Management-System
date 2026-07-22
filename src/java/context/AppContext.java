package context;

import dao.MenuDAO;
import dao.TableDAO;
import dao.OrderDAO;
import dao.StaffDAO;
import dao.InventoryDAO;
import dao.ShiftDAO;

import service.BrewStateService;
import websocket.BrewWebSocketHandler;

/**
 * The central application context that holds references to all Data Access Objects (DAOs),
 * services, and components used across the entire application. It follows the Singleton pattern.
 */
public class AppContext {
    private static final Object lock = new Object();
    private static AppContext instance;

    private final MenuDAO menuDAO;
    private final TableDAO tableDAO;
    private final OrderDAO orderDAO;
    private final StaffDAO staffDAO;

    private final InventoryDAO inventoryDAO;
    private final ShiftDAO shiftDAO;
    private final BrewStateService stateService;
    private final BrewWebSocketHandler webSocketHandler;

    private AppContext() {
        this.menuDAO = new MenuDAO();
        this.tableDAO = new TableDAO();
        this.orderDAO = new OrderDAO();
        this.staffDAO = new StaffDAO(); 
        this.inventoryDAO = new InventoryDAO();
        this.shiftDAO = new ShiftDAO();
        this.webSocketHandler = new BrewWebSocketHandler();
        this.stateService = new BrewStateService(menuDAO, tableDAO, orderDAO, staffDAO, inventoryDAO, shiftDAO, webSocketHandler);
    }

    /**
     * Retrieves the singleton instance of the AppContext.
     * 
     * @return the AppContext instance
     */
    public static AppContext getInstance() {
        if (instance == null) {
            synchronized (lock) {
                if (instance == null) {
                    instance = new AppContext();
                }
            }
        }
        return instance;
    }

    public MenuDAO getMenuDAO() { return menuDAO; }
    public TableDAO getTableDAO() { return tableDAO; }
    public OrderDAO getOrderDAO() { return orderDAO; }
    public StaffDAO getStaffDAO() { return staffDAO; }

    public InventoryDAO getInventoryDAO() { return inventoryDAO; }
    public ShiftDAO getShiftDAO() { return shiftDAO; }

    public BrewStateService getStateService() { return stateService; }
    public BrewWebSocketHandler getWebSocketHandler() { return webSocketHandler; }
}
