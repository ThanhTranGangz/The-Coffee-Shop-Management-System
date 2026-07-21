package service;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * ServletContextListener that schedules automatic shift carry-over.
 * Runs ShiftAutoScheduler.checkAndCarryOver() every hour.
 * The actual copy only happens on Saturday (checked inside checkAndCarryOver).
 */
@WebListener
public class ShiftSchedulerListener implements ServletContextListener {

    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "ShiftAutoScheduler");
            t.setDaemon(true);
            return t;
        });

        // Run every hour, with an initial delay of 1 minute to let the app fully start
        scheduler.scheduleAtFixedRate(() -> {
            try {
                ShiftAutoScheduler.checkAndCarryOver();
            } catch (Exception e) {
                System.err.println("[ShiftSchedulerListener] Error during auto carry-over: " + e.getMessage());
            }
        }, 1, 60, TimeUnit.MINUTES);

        System.out.println("[ShiftSchedulerListener] Auto shift carry-over scheduler started (runs every 60 minutes).");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) {
            scheduler.shutdown();
            try {
                if (!scheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                    scheduler.shutdownNow();
                }
            } catch (InterruptedException e) {
                scheduler.shutdownNow();
                Thread.currentThread().interrupt();
            }
            System.out.println("[ShiftSchedulerListener] Auto shift carry-over scheduler stopped.");
        }
    }
}
