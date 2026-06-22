package websocket;

import java.io.IOException;
import java.util.Collections;
import java.util.Set;
import java.util.ConcurrentModificationException;
import java.util.concurrent.ConcurrentHashMap;
import jakarta.websocket.Session;

/**
 * Manages active WebSocket sessions and provides broadcasting capabilities.
 */
public class BrewWebSocketHandler {
    // Thread-safe set of active browser sessions (using ConcurrentHashMap-backed set)
    private final Set<Session> sessions = Collections.newSetFromMap(new ConcurrentHashMap<>());

    /**
     * Adds a new WebSocket session to the active set.
     * 
     * @param session the session to add
     */
    public void addSession(Session session) {
        sessions.add(session);
    }

    /**
     * Removes a WebSocket session from the active set.
     * 
     * @param session the session to remove
     */
    public void removeSession(Session session) {
        sessions.remove(session);
    }

    /**
     * Broadcasts a text message payload (usually JSON update) to all active web clients.
     */
    public void broadcast(String message) {
        for (Session session : sessions) {
            if (session.isOpen()) {
                try {
                    session.getBasicRemote().sendText(message);
                } catch (IOException | IllegalStateException e) {
                    System.err.println("Failed to broadcast message to session " + session.getId() + ": " + e.getMessage());
                    sessions.remove(session); // stale session cleanup
                }
            }
        }
    }
}
