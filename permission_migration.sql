-- Chay file nay neu DB da ton tai tu truoc (bo qua neu vua tao moi bang create_table.sql + testData.sql)

USE CSMS_DB;
GO

INSERT INTO [Permission] (PermissionName, Description)
SELECT v.PermissionName, v.Description
FROM (VALUES
    ('VIEW_STAFF_ORDERS', N'View staff order board'),
    ('MANAGE_TABLE_QR', N'Manage table QR codes'),
    ('CANCEL_ORDER', N'Cancel pending orders')
) AS v(PermissionName, Description)
WHERE NOT EXISTS (
    SELECT 1 FROM [Permission] p WHERE p.PermissionName = v.PermissionName
);
GO

INSERT INTO [RolePermission] (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM [Role] r
CROSS JOIN [Permission] p
WHERE r.RoleName = 'MANAGER'
  AND p.PermissionName IN ('VIEW_STAFF_ORDERS', 'MANAGE_TABLE_QR', 'CANCEL_ORDER')
  AND NOT EXISTS (
      SELECT 1 FROM [RolePermission] rp
      WHERE rp.RoleID = r.RoleID AND rp.PermissionID = p.PermissionID
  );
GO

INSERT INTO [RolePermission] (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM [Role] r
JOIN [Permission] p ON p.PermissionName IN ('VIEW_STAFF_ORDERS', 'CANCEL_ORDER')
WHERE r.RoleName = 'CASHIER'
  AND NOT EXISTS (
      SELECT 1 FROM [RolePermission] rp
      WHERE rp.RoleID = r.RoleID AND rp.PermissionID = p.PermissionID
  );
GO

INSERT INTO [RolePermission] (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM [Role] r
JOIN [Permission] p ON p.PermissionName = 'VIEW_STAFF_ORDERS'
WHERE r.RoleName = 'BARISTA'
  AND NOT EXISTS (
      SELECT 1 FROM [RolePermission] rp
      WHERE rp.RoleID = r.RoleID AND rp.PermissionID = p.PermissionID
  );
GO

INSERT INTO [Staff] (Username, [Password], PIN_Code, FullName, RoleID, IsActive)
SELECT v.Username, v.[Password], v.PIN_Code, v.FullName, r.RoleID, 1
FROM (VALUES
    ('cashier', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
             '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4',
             N'Thu ngân Demo', 'CASHIER'),
    ('barista', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
             '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4',
             N'Pha chế Demo', 'BARISTA'),
    ('waiter', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
             '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4',
             N'Phục vụ Demo', 'WAITER')
) AS v(Username, [Password], PIN_Code, FullName, RoleName)
JOIN [Role] r ON r.RoleName = v.RoleName
WHERE NOT EXISTS (SELECT 1 FROM [Staff] s WHERE s.Username = v.Username);
GO
