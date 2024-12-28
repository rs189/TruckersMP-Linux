import sys
import os
import subprocess
from PyQt5.QtCore import Qt, QThread, pyqtSignal
from PyQt5.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QPushButton, QPlainTextEdit, QProgressBar, QWidget, QMessageBox
import re

class InstallerThread(QThread):
    log_signal = pyqtSignal(str)
    progress_signal = pyqtSignal(int)

    def run(self):
        # Use the APPDIR environment variable to find the correct path
        appdir = os.getenv('APPDIR', '.')
        script_path = os.path.join(appdir, 'usr', 'bin', 'install_truckersmp.sh')
        
        # Check if the script exists
        if not os.path.isfile(script_path):
            self.log_signal.emit(f"Error: {script_path} not found!")
            return

        process = subprocess.Popen(
            [script_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        
        # Read output from the process
        for line in process.stdout:
            if not re.match(r"(PROGRESS|ERROR|INFO):", line.strip()):
                self.log_signal.emit(line.strip())

            # Look for "PROGRESS:<number>" format
            match = re.match(r"PROGRESS:(\d+)", line.strip())
            if match:
                progress = int(match.group(1))
                self.progress_signal.emit(progress)

            # Look for "ERROR:<message>" format
            match = re.match(r"ERROR:(.*)", line.strip())
            if match:
                QMessageBox.critical(None, "Error", match.group(1))

        process.wait()
        if process.returncode == 0:
            self.log_signal.emit("Installation completed successfully.")
        else:
            self.log_signal.emit(f"Installation failed with code {process.returncode}.")

window = None

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("TruckersMP Installer")
        self.setGeometry(100, 100, 600, 400)

        # Central widget and layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout()
        central_widget.setLayout(layout)

        # Log window
        self.log_window = QPlainTextEdit(self)
        self.log_window.setReadOnly(True)
        layout.addWidget(self.log_window)

        # Progress bar
        self.progress_bar = QProgressBar(self)
        self.progress_bar.setRange(0, 100)
        self.progress_bar.setValue(0)
        layout.addWidget(self.progress_bar)

        # Install button
        self.install_button = QPushButton("Install", self)
        self.install_button.clicked.connect(self.start_installation)
        layout.addWidget(self.install_button)

        # Thread for installation
        self.installer_thread = InstallerThread()
        self.installer_thread.log_signal.connect(self.update_log)
        self.installer_thread.progress_signal.connect(self.update_progress)

    def start_installation(self):
        self.install_button.setEnabled(False)
        self.log_window.clear()
        self.installer_thread.start()

    def update_log(self, message):
        self.log_window.appendPlainText(message)

    def update_progress(self, value):
        self.progress_bar.setValue(value)
        if value == 100:
            QMessageBox.information(self, "Installation Complete", "Installation completed successfully.")
            #sys.exit(0)
            window.close()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec_())
