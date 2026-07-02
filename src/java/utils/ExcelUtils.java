package utils;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class ExcelUtils {
    private static final String[] TEMPLATE_HEADERS =
            {"Tên (VI)", "Tên (EN)", "Danh mục", "Giá", "Đường dẫn ảnh", "Đang bán (1/0)"};

    public static List<Map<String, Object>> parseMenuRows(InputStream in) throws Exception {
        List<Map<String, Object>> result = new ArrayList<>();
        try (Workbook workbook = WorkbookFactory.create(in)) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet == null || sheet.getLastRowNum() < 0) return result;

            Map<String, Integer> columns = mapColumns(sheet.getRow(sheet.getFirstRowNum()));
            for (int r = sheet.getFirstRowNum() + 1; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row == null) continue;
                String nameVi = cellText(row, columns.get("nameVi"));
                if (nameVi.isEmpty()) continue;

                Map<String, Object> data = new LinkedHashMap<>();
                data.put("nameVi", nameVi);
                String nameEn = cellText(row, columns.get("nameEn"));
                if (!nameEn.isEmpty()) data.put("nameEn", nameEn);
                String category = cellText(row, columns.get("category"));
                if (!category.isEmpty()) data.put("category", category);
                data.put("price", cellNumber(row, columns.get("price")));
                String imagePath = cellText(row, columns.get("imagePath"));
                if (!imagePath.isEmpty()) data.put("imagePath", imagePath);
                Boolean active = cellBoolean(row, columns.get("active"));
                if (active != null) data.put("active", active);
                result.add(data);
            }
        }
        return result;
    }

    public static byte[] buildTemplate() throws Exception {
        try (XSSFWorkbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Menu");
            org.apache.poi.ss.usermodel.CellStyle headerStyle = workbook.createCellStyle();
            org.apache.poi.ss.usermodel.Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerStyle.setFont(headerFont);

            Row header = sheet.createRow(0);
            for (int i = 0; i < TEMPLATE_HEADERS.length; i++) {
                Cell cell = header.createCell(i);
                cell.setCellValue(TEMPLATE_HEADERS[i]);
                cell.setCellStyle(headerStyle);
                sheet.setColumnWidth(i, 22 * 256);
            }

            Object[][] examples = {
                    {"Cà phê sữa đá", "Iced Milk Coffee", "Cà phê", 25000, "", 1},
                    {"Trà đào cam sả", "Peach Lemongrass Tea", "Trà", 35000, "", 1},
            };
            for (int r = 0; r < examples.length; r++) {
                Row row = sheet.createRow(r + 1);
                Object[] values = examples[r];
                row.createCell(0).setCellValue((String) values[0]);
                row.createCell(1).setCellValue((String) values[1]);
                row.createCell(2).setCellValue((String) values[2]);
                row.createCell(3).setCellValue((int) values[3]);
                row.createCell(4).setCellValue((String) values[4]);
                row.createCell(5).setCellValue((int) values[5]);
            }

            // Note goes in a column past the data columns so the parser never mistakes it for a nameVi cell.
            Row note = sheet.createRow(examples.length + 2);
            note.createCell(TEMPLATE_HEADERS.length + 1).setCellValue("Ghi chú: xoá các dòng ví dụ ở trên trước khi nhập món thật. "
                    + "Danh mục hợp lệ: Cà phê, Trà, Đặc biệt, Bánh ngọt. "
                    + "Giá từ 10.000đ-200.000đ và chia hết cho 1.000đ. "
                    + "Để trống cột Ảnh/Đang bán sẽ dùng giá trị mặc định.");

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            workbook.write(out);
            return out.toByteArray();
        }
    }

    private static Map<String, Integer> mapColumns(Row headerRow) {
        Map<String, Integer> columns = new HashMap<>();
        if (headerRow != null) {
            for (Cell cell : headerRow) {
                String field = fieldFor(normalize(cellText(headerRow, cell.getColumnIndex())));
                if (field != null) columns.put(field, cell.getColumnIndex());
            }
        }
        columns.putIfAbsent("nameVi", 0);
        columns.putIfAbsent("nameEn", 1);
        columns.putIfAbsent("category", 2);
        columns.putIfAbsent("price", 3);
        columns.putIfAbsent("imagePath", 4);
        columns.putIfAbsent("active", 5);
        return columns;
    }

    private static String fieldFor(String normalizedHeader) {
        if (normalizedHeader.equals("tenvi")) return "nameVi";
        if (normalizedHeader.equals("tenen")) return "nameEn";
        if (normalizedHeader.equals("danhmuc")) return "category";
        if (normalizedHeader.equals("gia")) return "price";
        if (normalizedHeader.startsWith("duongdan")) return "imagePath";
        if (normalizedHeader.startsWith("dangban")) return "active";
        return null;
    }

    private static String normalize(String value) {
        if (value == null) return "";
        String folded = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .replace('đ', 'd').replace('Đ', 'D')
                .toLowerCase(Locale.ROOT);
        return folded.replaceAll("[^a-z0-9]", "");
    }

    private static String cellText(Row row, Integer colIndex) {
        if (row == null || colIndex == null) return "";
        Cell cell = row.getCell(colIndex);
        if (cell == null) return "";
        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue().trim();
            case NUMERIC:
                double num = cell.getNumericCellValue();
                return num == Math.floor(num) ? String.valueOf((long) num) : String.valueOf(num);
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                try {
                    return cell.getStringCellValue().trim();
                } catch (Exception e) {
                    return String.valueOf(cell.getNumericCellValue());
                }
            default:
                return "";
        }
    }

    private static int cellNumber(Row row, Integer colIndex) {
        String digits = cellText(row, colIndex).replaceAll("[^0-9]", "");
        if (digits.isEmpty()) return 0;
        try {
            return Integer.parseInt(digits);
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private static Boolean cellBoolean(Row row, Integer colIndex) {
        if (row == null || colIndex == null) return null;
        Cell cell = row.getCell(colIndex);
        if (cell == null) return null;
        if (cell.getCellType() == CellType.BOOLEAN) return cell.getBooleanCellValue();
        String text = normalize(cellText(row, colIndex));
        if (text.isEmpty()) return null;
        return !(text.equals("0") || text.equals("false") || text.equals("khong"));
    }
}
