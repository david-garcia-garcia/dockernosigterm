# Define C# code with a method to handle console control events
$code = @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class ConsoleCtrlHandler {
    [DllImport("Kernel32")]
    public static extern bool SetConsoleCtrlHandler(HandlerRoutine Handler, bool Add);

    public delegate bool HandlerRoutine(CtrlTypes CtrlType);

    public enum CtrlTypes {
        CTRL_C_EVENT = 0,
        CTRL_BREAK_EVENT,
        CTRL_CLOSE_EVENT,
        CTRL_LOGOFF_EVENT = 5,
        CTRL_SHUTDOWN_EVENT
    }

    private static bool _shutdownRequested = false;
    private static bool _shutdownAllowed = false;

    public static void SetShutdownAllowed(bool allowed) {
        _shutdownAllowed = allowed;
    }

    public static bool GetShutdownRequested() {
        return _shutdownRequested;
    }

    public static bool ConsoleCtrlCheck(CtrlTypes ctrlType) {
        switch (ctrlType) {
            case CtrlTypes.CTRL_CLOSE_EVENT:
            case CtrlTypes.CTRL_SHUTDOWN_EVENT:
                _shutdownRequested = true;
                System.Diagnostics.Stopwatch stopwatch = System.Diagnostics.Stopwatch.StartNew();
                // Wait until the PowerShell script sets _shutdownAllowed to true
                while (!_shutdownAllowed && stopwatch.Elapsed.TotalSeconds < 120) {
                    Thread.Sleep(1000); // Check every second
                }
                return true; // Indicate that the event has been handled
            default:
                return false;
        } 
    }
}
"@

# Add the C# type to the current PowerShell session
Add-Type -TypeDefinition $code -ReferencedAssemblies "System.Runtime.InteropServices"

# Create a delegate for the handler method
$handler = [ConsoleCtrlHandler+HandlerRoutine]::CreateDelegate([ConsoleCtrlHandler+HandlerRoutine], [ConsoleCtrlHandler], "ConsoleCtrlCheck");

# Register the handler
[ConsoleCtrlHandler]::SetConsoleCtrlHandler($handler, $true);

# Your script logic here
Write-Host "Waiting for console control event..."
while (-not [ConsoleCtrlHandler]::GetShutdownRequested()) {
    Start-Sleep -Seconds 1;
}

# Simulate a task that needs to be completed before shutdown
for ($i = 1; $i -le 20; $i++) {
    Write-Host "Task progress: $i of 20"
    Start-Sleep -Seconds 1
}

# Allow the shutdown to proceed
[ConsoleCtrlHandler]::SetShutdownAllowed($true)