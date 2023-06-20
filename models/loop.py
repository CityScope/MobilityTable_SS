import pyautogui
import time
import pygetwindow as gw
import schedule
import win32gui

#Find the right window name
if False:
    # Get all open windows
    windows = gw.getAllTitles()

    # Print the titles of all windows
    for window in windows:
        print(window)

#Change title
if False:
    #Avoid backlash command with r
    window_title= r'test - C:\Users\Naroa\Documents\GitHub\FoodDeliveries\models\TestPlot.gaml'
    hwnd = win32gui.FindWindow(None, window_title)

    new_title = 'GAMA'
    win32gui.SetWindowText(hwnd, new_title)


if True:
    def restart_gama():

        # Find the GAMA window by its title
        gama_windows = gw.getWindowsWithTitle('GAMA')

        if len(gama_windows) == 0:
            print('GAMA window not found')
            return

        gama_windows[0].activate()

        # Simulate pressing the Control + R keyboard shortcut
        pyautogui.hotkey('ctrl', 'r')
        time.sleep(5)  # Wait for GAMA to restart (adjust if needed)

    # Schedule the restart every hour
    schedule.every(10).seconds.do(restart_gama)

    while True:
        schedule.run_pending()
        time.sleep(1)

