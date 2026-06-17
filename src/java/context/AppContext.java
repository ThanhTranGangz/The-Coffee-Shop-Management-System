package context;

import dao.MenuDAO;
import dao.TableDAO;
import dao.OrderDAO;
import service.BrewStateService;
import websocket.BrewWebSocketHandler;

public class AppContext {
    private static final Object lock = new Object();
    private static AppContext instance;

    private final MenuDAO menuDAO;
    private final TableDAO tableDAO;
    private final OrderDAO orderDAO;
    private final BrewStateService stateService;
    private final BrewWebSocketHandler webSocketHandler;

    private AppContext() {
        this.menuDAO = new MenuDAO();
        this.tableDAO = new TableDAO();
        this.orderDAO = new OrderDAO();
        this.webSocketHandler = new BrewWebSocketHandler();
        this.stateService = new BrewStateService(menuDAO, tableDAO, orderDAO, webSocketHandler);
    }

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
    public BrewStateService getStateService() { return stateService; }
    public BrewWebSocketHandler getWebSocketHandler() { return webSocketHandler; }
}
