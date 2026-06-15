package websocket;

import context.AppContext;
import jakarta.websocket.OnClose;
import jakarta.websocket.OnError;
import jakarta.websocket.OnMessage;
import jakarta.websocket.OnOpen;
import jakarta.websocket.Session;
import jakarta.websocket.server.ServerEndpoint;

@ServerEndpoint("/ws")
public class BrewWebSocketEndpoint {

    @OnOpen
    public void onOpen(Session session) {
        System.out.println("WebSocket connection opened: " + session.getId());
        AppContext.getInstance().getWebSocketHandler().addSession(session);
    }

    @OnMessage
    public void onMessage(String message, Session session) {
        System.out.println("WebSocket message received from " + session.getId() + ": " + message);
        // We ping back if clients send custom commands or keepalives
        if ("ping".equalsIgnoreCase(message)) {
            try {
                session.getBasicRemote().sendText("pong");
            } catch (Exception e) {
                System.err.println("Error responding to ping: " + e.getMessage());
            }
        }
    }

    @OnClose
    public void onClose(Session session) {
        System.out.println("WebSocket connection closed: " + session.getId());
        AppContext.getInstance().getWebSocketHandler().removeSession(session);
    }

    @OnError
    public void onError(Throwable throwable, Session session) {
        System.err.println("WebSocket error in session " + (session != null ? session.getId() : "null") + ": " + throwable.getMessage());
        if (session != null) {
            AppContext.getInstance().getWebSocketHandler().removeSession(session);
        }
    }
}
