import pyautogui
import time
import pygetwindow as gw
import schedule

#Find the right window name
if False:
    # Get all open windows
    windows = gw.getAllTitles()

    # Print the titles of all windows
    for window in windows:
        print(window)



def restart_gama():
    #write
    print('Hello')

    # Find the GAMA window by its title
    gama_window = gw.getWindowWithTitle('Gama')[0]
    gama_window.activate()

    # Simulate pressing the Control + R keyboard shortcut
    pyautogui.hotkey('command', 'r')
    time.sleep(5)  # Wait for GAMA to restart (adjust if needed)

# Schedule the restart every hour
schedule.every().minute.do(restart_gama)

while True:
    schedule.run_pending()
    time.sleep(1)

