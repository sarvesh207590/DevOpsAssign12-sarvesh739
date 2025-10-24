from selenium import webdriver
from selenium.webdriver.common.by import By
import time

driver = webdriver.Firefox()  # or Chrome if chromedriver installed
driver.get("http://<manager_public_ip>/")
time.sleep(2)

# check title contains Login
assert "Login" in driver.title or driver.find_element(By.TAG_NAME, "h2").text == "Login"

driver.quit()
