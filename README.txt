Running the project will be a bit difficult, so if a live demo is desired, it may be best to contact us to do so.

The project requires iDevices to fully function so cannot be effectively run from the simulator. The code base can be examined and the simulator can attempt to run it, though, as long as the project is opened with Xcode. To build onto an iDevice would require a developer profile with keychains installed on the local computer. This process can be somewhat complicated...

The code is broken into two primary compnents:

ViewController class -> contains networking logic and setup for main screen (where passcode can be set, credit can be viewed, etc.). Also contains methods for mesh handling and ferrying of multipeer sessions between hosts.

WebViewController -> Interface on top of network logic in ViewController (browse screen). This handles presentation of a practical demo of data being passed through the mesh. Essentially it implements a webview that takes all requests and routes them through the mesh, gets back the resultant data and uses that data to instantiate the desired webpages.