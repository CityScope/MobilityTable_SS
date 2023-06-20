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
    window_title= r'test - C:\Users\City Science\Documents\GitHub\FoodDeliveries\models\TestPlot.gaml'
    hwnd = win32gui.FindWindow(None, window_title)

    new_title = 'GAMA'
    win32gui.SetWindowText(hwnd, new_title)


if True:
    def restart_gama():

        #Avoid backlash command with r
        #window_title= r'test - C:\Users\City Science\Documents\GitHub\FoodDeliveries\models\TestPlot.gaml'
        window_title= r'generalScenario - C:\Users\City Science\Documents\GitHub\FoodDeliveries\models\main.gaml'

        # Find the GAMA window by its title
        gama_windows = gw.getWindowsWithTitle(window_title)

        if len(gama_windows) == 0:
            print('GAMA window not found')
            return

        gama_windows[0].activate()

        # Simulate pressing the Control + R keyboard shortcut
        pyautogui.hotkey('ctrl', 'r')
        time.sleep(5)  # Wait for GAMA to restart (adjust if needed)

    # Schedule the restart every hour
    schedule.every(30).minute.do(restart_gama)

    while True:
        schedule.run_pending()
        time.sleep(60)

