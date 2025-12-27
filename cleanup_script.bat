@echo off
REM ============================================================================
REM PICCTURE CLEANUP SCRIPT - WINDOWS
REM Run this from your Flutter project root (where pubspec.yaml is)
REM ============================================================================

echo 🧹 Starting Piccture lib cleanup...
echo.

REM ============================================================================
REM 1. OLD/BACKUP FILES
REM ============================================================================
echo Deleting old/backup files...
del /q "lib\main_old.dart" 2>nul
del /q "lib\picctureapp_old.dart" 2>nul
del /q "lib\features\auth\login\login_controller_old_.dart" 2>nul
del /q "lib\features\feed\day_album_viewer_screen_vOld.dart" 2>nul
del /q "lib\features\home\_home_screen_v3_old_.dart" 2>nul
del /q "lib\features\navigation\main_navigation_old.dart" 2>nul
del /q "lib\features\post\create\post_model_old.dart" 2>nul
echo Done.

REM ============================================================================
REM 2. DRAWER/SNAPOUT FILES
REM ============================================================================
echo Deleting drawer/snapout files...
rmdir /s /q "lib\features\settingsbreadcrumb" 2>nul
del /q "lib\features\settings\settings_drawer_complete.dart" 2>nul
del /q "lib\features\settings\settings_screen_v2.dart" 2>nul
echo Done.

REM ============================================================================
REM 3. DUPLICATE/DEAD FILES
REM ============================================================================
echo Deleting duplicate/dead files...
del /q "lib\features\profile\widgets\verified_badge.dart" 2>nul
del /q "lib\features\user\models\user_model.dart" 2>nul
del /q "lib\features\user\services\account_state_guard.dart" 2>nul
del /q "lib\features\post\quote\replies_list_screen.dart" 2>nul
del /q "lib\features\post\reply\_replies_list_screen_.dart" 2>nul
del /q "lib\features\post\quote\quote.dart" 2>nul
del /q "lib\features\navigation\navigator_state_controller.dart" 2>nul
del /q "lib\features\navigation\plus_menu_controller.dart" 2>nul
del /q "lib\features\follow\widgets\follow_button.dart" 2>nul
del /q "lib\features\follow\widgets\follow_list_body.dart" 2>nul
del /q "lib\features\follow\widgets\follow_user_row.dart" 2>nul
echo Done.

REM ============================================================================
REM 4. UNUSED CORE FILES
REM ============================================================================
echo Deleting unused core files...
del /q "lib\core\widgets\app_scaffold.dart" 2>nul
del /q "lib\core\widgets\app_app_bar.dart" 2>nul
del /q "lib\core\widgets\loading_skeletons.dart" 2>nul
del /q "lib\core\utils\image_utils.dart" 2>nul
del /q "lib\routes\app_routes.dart" 2>nul
echo Done.

REM ============================================================================
REM 5. UNUSED FEATURE FILES
REM ============================================================================
echo Deleting unused feature files...
del /q "lib\features\pics\pics_gallery_screen.dart" 2>nul
del /q "lib\features\share\share_service.dart" 2>nul
del /q "lib\features\post\details\post_details_controller.dart" 2>nul
del /q "lib\features\post\details\post_details_screen.dart" 2>nul
del /q "lib\features\post\details\post_details_service.dart" 2>nul
echo Done.

REM ============================================================================
REM 6. EMPTY FOLDERS
REM ============================================================================
echo Removing empty folders...
rmdir "lib\debug" 2>nul
rmdir "lib\features\pics" 2>nul
rmdir "lib\features\share" 2>nul
rmdir "lib\features\post\details" 2>nul
rmdir "lib\routes" 2>nul
rmdir "lib\features\user\models" 2>nul
rmdir "lib\core\utils" 2>nul
echo Done.

REM ============================================================================
REM DONE
REM ============================================================================
echo.
echo ✅ Cleanup complete!
echo.
echo NEXT STEPS:
echo 1. Replace lib\picctureapp.dart with picctureapp_fixed.dart
echo 2. Run: flutter clean
echo 3. Run: flutter pub get
echo 4. Run: flutter analyze
echo.
pause
