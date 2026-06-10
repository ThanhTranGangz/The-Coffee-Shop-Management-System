INSERT INTO [Permission] (PermissionName, Description)
VALUES
('MANAGE_STAFF', 'Manage staff accounts'),
('MANAGE_ROLE', 'Manage staff roles'),
('VIEW_REPORT', 'View sales reports'),
('MANAGE_VOUCHER', 'Manage vouchers'),
('MANAGE_MEMBER', 'Manage members'),
('CREATE_ORDER', 'Create customer orders'),
('CONFIRM_PAYMENT', 'Confirm order payment'),
('VIEW_KITCHEN_ORDER', 'View kitchen orders'),
('UPDATE_ORDER_STATUS', 'Update order item status'),
('VIEW_STAFF_ORDERS', 'View staff order board'),
('MANAGE_TABLE_QR', 'Manage table QR codes'),
('CANCEL_ORDER', 'Cancel pending orders');

INSERT INTO [RolePermission] (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM [Role] r
CROSS JOIN [Permission] p
WHERE r.RoleName = 'MANAGER';

INSERT INTO [RolePermission] (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM [Role] r
JOIN [Permission] p 
    ON p.PermissionName IN (
        'CREATE_ORDER',
        'CONFIRM_PAYMENT',
        'VIEW_STAFF_ORDERS',
        'CANCEL_ORDER'
    )
WHERE r.RoleName = 'CASHIER';

INSERT INTO [RolePermission] (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM [Role] r
JOIN [Permission] p 
    ON p.PermissionName IN (
        'VIEW_KITCHEN_ORDER',
        'UPDATE_ORDER_STATUS',
        'VIEW_STAFF_ORDERS'
    )
WHERE r.RoleName = 'BARISTA';

INSERT INTO [RolePermission] (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM [Role] r
JOIN [Permission] p 
    ON p.PermissionName IN ('CREATE_ORDER')
WHERE r.RoleName = 'WAITER';

-- Demo staff de test phan quyen (mat khau: 123456, PIN: 1234)
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
SELECT s.Username, r.RoleName
FROM Staff s
JOIN Role r ON s.RoleID = r.RoleID
WHERE s.Username = 'admin';
