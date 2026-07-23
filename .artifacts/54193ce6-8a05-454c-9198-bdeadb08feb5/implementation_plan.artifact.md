# Implementation Plan - Manage Pelanggan (Admin Dashboard)

Add functionality for admins to edit and delete customer profiles from the admin dashboard.

## User Review Required

> [!WARNING]
> Deleting a customer profile will also affect their transaction history and saldo. If there are foreign key constraints in the database, the deletion might fail unless cascaded.

## Proposed Changes

### Data Service

#### [MODIFY] [db_service.dart](file:///C:/Users/ariha/Documents/Flutter/laundryin/lib/services/db_service.dart)
- Add `updatePelanggan(String id, Map<String, dynamic> data)` to update profile information.
- Add `deletePelanggan(String id)` to remove a profile.

### Admin Interface

#### [MODIFY] [admin_page.dart](file:///C:/Users/ariha/Documents/Flutter/laundryin/lib/pages/admin_page.dart)
- Update `_PelangganTab` to include **Edit** and **Hapus** actions in the detail bottom sheet.
- Implement `_formPelanggan` dialog to edit customer details (Name, Email, Saldo).
- Implement `_hapusPelanggan` confirmation dialog.

## Verification Plan

### Manual Verification
1. Log in as an admin.
2. Navigate to the **Pelanggan** tab.
3. Tap on a customer to open details.
4. Test **Edit**: Change the customer's name or saldo and verify the update.
5. Test **Hapus**: Delete a test customer and verify they are removed from the list.
