package service;

import dao.ShiftDAO;
import model.Shift;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import java.util.UUID;

/**
 * Automatically copies the current week's shift schedule to the next week
 * if the next week has no shifts assigned yet.
 */
public class ShiftAutoScheduler {

    private static final ShiftDAO shiftDAO = new ShiftDAO();

    /**
     * Checks if today is Saturday, and if the next week has no shifts,
     * copies the current week's schedule to the next week.
     * Called periodically by a scheduled executor.
     */
    public static void checkAndCarryOver() {
        LocalDate today = LocalDate.now();
        if (today.getDayOfWeek() != DayOfWeek.SATURDAY) {
            return;
        }

        LocalDate currentMonday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDate nextMonday = currentMonday.plusWeeks(1);

        int copied = carryOver(currentMonday.toString(), nextMonday.toString());
        if (copied > 0) {
            System.out.println("[ShiftAutoScheduler] Auto carry-over completed: " + copied + " shifts copied from week " + currentMonday + " to week " + nextMonday);
        }
    }

    /**
     * Copies shifts from the source week to the target week.
     * Skips if the target week already has shifts.
     * Copies ALL staff shifts (including inactive staff) as per business requirement.
     *
     * @param sourceMondayDate the Monday date of the source week (YYYY-MM-DD)
     * @param targetMondayDate the Monday date of the target week (YYYY-MM-DD)
     * @return the number of shifts copied, or 0 if the target week already has shifts
     */
    public static int carryOver(String sourceMondayDate, String targetMondayDate) {
        // Get all shifts from the source week
        List<Shift> sourceShifts = shiftDAO.getShiftsByWeek(sourceMondayDate);
        if (sourceShifts.isEmpty()) {
            System.out.println("[ShiftAutoScheduler] Source week " + sourceMondayDate + " has no shifts to copy.");
            return 0;
        }

        LocalDate sourceMonday = LocalDate.parse(sourceMondayDate);
        LocalDate targetMonday = LocalDate.parse(targetMondayDate);

        // Pre-calculate which shift slots are already filled in the target week
        // We only want to skip copying if the slot was filled BEFORE the copy started.
        List<Shift> targetShifts = shiftDAO.getShiftsByWeek(targetMondayDate);
        java.util.Set<String> preFilledSlots = new java.util.HashSet<>();
        for (Shift s : targetShifts) {
            preFilledSlots.add(s.getShiftDate() + "_" + s.getShiftName());
        }

        int copied = 0;
        for (Shift source : sourceShifts) {
            // Calculate new date: shift date + 7 days (difference between target and source week)
            LocalDate sourceDate = LocalDate.parse(source.getShiftDate());
            long dayOffset = sourceDate.getDayOfWeek().getValue() - DayOfWeek.MONDAY.getValue();
            LocalDate targetDate = targetMonday.plusDays(dayOffset);

            // Check if this specific shift slot was ALREADY filled before we started copying
            String slotKey = targetDate.toString() + "_" + source.getShiftName();
            if (preFilledSlots.contains(slotKey)) {
                continue; // Skip this one, because the slot was already manually scheduled
            }

            // Create new shift with new ID, new date, status reset, notes cleared
            String newId = "s" + System.currentTimeMillis() + "-" + Math.abs(UUID.randomUUID().toString().hashCode());

            Shift newShift = new Shift(
                newId,
                source.getStaffId(),
                source.getStaffName(),
                targetDate.toString(),
                source.getShiftName(),
                source.getHours(),
                "Đã xếp lịch",     // Reset status
                "",                  // Clear notes
                source.getAssignedRole()
            );

            try {
                shiftDAO.save(newShift);
                copied++;
            } catch (Exception e) {
                System.err.println("[ShiftAutoScheduler] Failed to copy shift for staff " + source.getStaffName() + " on " + targetDate + ": " + e.getMessage());
            }
        }

        return copied;
    }
}
