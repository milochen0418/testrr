# Remote Control via the Intent Interface

The Intent Interface described herein allows controlling the VNC server from other packages.

## Use Cases
- automation apps like [MacroDroid](https://www.macrodroid.com/), [Automate](https://llamalab.com/automate/) or
[Tasker](https://tasker.joaoapps.com/)
- to be called from code  of other apps

## Specification

You basically send an explicit Intent to `com.auodplus.satis.fly.MainService` with one of
the following Actions and associated Extras set:

* `com.auodplus.satis.fly.ACTION_START`: Starts the server.
  * `com.auodplus.satis.fly.EXTRA_ACCESS_KEY`: Required String Extra containing the remote control interface's access key. You can get/set this from the Admin Panel. 
  * `com.auodplus.satis.fly.EXTRA_REQUEST_ID`: Optional String Extra containing a unique id for this request. Used to identify the answer from the service.
  * `com.auodplus.satis.fly.EXTRA_PORT`: Optional Integer Extra setting the listening port. Set to `-1` to disable listening.
  * `com.auodplus.satis.fly.EXTRA_PASSWORD`: Optional String Extra containing VNC password.
  * `com.auodplus.satis.fly.EXTRA_SCALING`: Optional Float Extra between 0.0 and 1.0 describing the server-side framebuffer scaling.
  * `com.auodplus.satis.fly.EXTRA_VIEW_ONLY`:  Optional Boolean Extra toggling view-only mode.
  * `com.auodplus.satis.fly.EXTRA_SHOW_POINTERS`:  Optional Boolean Extra toggling per-client mouse pointers.
  * `com.auodplus.satis.fly.EXTRA_FILE_TRANSFER`: Optional Boolean Extra toggling the file transfer feature.
  * `com.auodplus.satis.fly.EXTRA_FALLBACK_SCREEN_CAPTURE`: Optional Boolean Extra indicating whether to start with fallback screen capture that does not need a
     user interaction to start but is slow and needs view-only to be off. Only applicable to Android 10 and newer.

* `com.auodplus.satis.fly.ACTION_CONNECT_REVERSE`: Make an outbound connection to a listening viewer.
  * `com.auodplus.satis.fly.EXTRA_ACCESS_KEY`: Required String Extra containing the remote control interface's access key. You can get/set this from the Admin Panel.
  * `com.auodplus.satis.fly.EXTRA_REQUEST_ID`: Optional String Extra containing a unique id for this request. Used to identify the answer from the service.
  * `com.auodplus.satis.fly.EXTRA_HOST`: Required String Extra setting the host to connect to.
  * `com.auodplus.satis.fly.EXTRA_PORT`: Optional Integer Extra setting the remote port.
  * `com.auodplus.satis.fly.EXTRA_RECONNECT_TRIES`: Optional Integer Extra setting the number of tries reconnecting a once established connection. Needs request id to be set.

* `com.auodplus.satis.fly.ACTION_CONNECT_REPEATER` Make an outbound connection to a repeater.
  * `com.auodplus.satis.fly.EXTRA_ACCESS_KEY`: Required String Extra containing the remote control interface's access key. You can get/set this from the Admin Panel.
  * `com.auodplus.satis.fly.EXTRA_REQUEST_ID`: Optional String Extra containing a unique id for this request. Used to identify the answer from the service.
  * `com.auodplus.satis.fly.EXTRA_HOST`: Required String Extra setting the host to connect to.
  * `com.auodplus.satis.fly.EXTRA_PORT`: Optional Integer Extra setting the remote port.
  * `com.auodplus.satis.fly.EXTRA_REPEATER_ID`: Required String Extra setting the ID on the repeater.
  * `com.auodplus.satis.fly.EXTRA_RECONNECT_TRIES`: Optional Integer Extra setting the number of tries reconnecting a once established connection. Needs request id to be set.

* `com.auodplus.satis.fly.ACTION_GET_CLIENTS` Get a JSON array of currently handled clients.
  * `com.auodplus.satis.fly.EXTRA_ACCESS_KEY`: Required String Extra containing the remote control interface's access key. You can get/set this from the Admin Panel.
  * `com.auodplus.satis.fly.EXTRA_REQUEST_ID`: Optional String Extra containing a unique id for this request. Used to identify the answer from the service.
  * `com.auodplus.satis.fly.EXTRA_RECEIVER`: Required String Extra containing the name of the package the answer should be sent to.

* `com.auodplus.satis.fly.ACTION_DISCONNECT` Disconnect the specified client.
  * `com.auodplus.satis.fly.EXTRA_ACCESS_KEY`: Required String Extra containing the remote control interface's access key. You can get/set this from the Admin Panel.
  * `com.auodplus.satis.fly.EXTRA_REQUEST_ID`: Optional String Extra containing a unique id for this request. Used to identify the answer from the service.
  * `com.auodplus.satis.fly.EXTRA_CLIENT_CONNECTION_ID`: Optional/Required Long Extra containing the connection id of the client to disconnect. Either this or
    `com.auodplus.satis.fly.EXTRA_CLIENT_REQUEST_ID` must be given. If both are given, only `com.auodplus.satis.fly.EXTRA_CLIENT_CONNECTION_ID` is
    handled.
  * `com.auodplus.satis.fly.EXTRA_CLIENT_REQUEST_ID`: Optional/Required String Extra containing the request id of the reverse/repeater client to disconnect.
    Either this or `com.auodplus.satis.fly.EXTRA_CLIENT_CONNECTION_ID` must be given. If both are given, only `com.auodplus.satis.fly.EXTRA_CLIENT_CONNECTION_ID` is handled.

* `com.auodplus.satis.fly.ACTION_STOP`: Stops the server.
  * `com.auodplus.satis.fly.EXTRA_ACCESS_KEY`: Required String Extra containing the remote control interface's access key. You can get/set this from the Admin Panel.
  * `com.auodplus.satis.fly.EXTRA_REQUEST_ID`: Optional String Extra containing a unique id for this request. Used to identify the answer from the service.

The service answers with a Broadcast Intent with its Action mirroring your request:

* Action: one of the above Actions you requested
  * `com.auodplus.satis.fly.EXTRA_REQUEST_ID`: The request id this answer is for.
  * `com.auodplus.satis.fly.EXTRA_REQUEST_SUCCESS`: Boolean Extra describing the outcome of the request.
  * `com.auodplus.satis.fly.EXTRA_CLIENTS`: If action is `com.auodplus.satis.fly.ACTION_GET_CLIENTS`, a String Extra containing a JSON array of
    currently handled clients:
    ```json
    [
       {
         "connectionId": 123454321,
         "host": "192.168.1.2",
         "port": 5500,
         "repeaterId": "someStringId",
         "requestId": "someStringId"
       }
    ]
    ```
     - `connectionId` optional, only set when there is an actual connection (it might not be if a reverse/repeater client is in reconnect mode)
     - `host` is remote IP address or hostname, either the source or the reverse/repeater destination
     - `port` optional, port of reverse/repeater remote
     - `repeaterId` optional, id for repeater remote
     - `requestId` optional, the id given when initiating a reverse/repeater connection

There is one special case where the service sends a Broadcast Intent with action
`com.auodplus.satis.fly.ACTION_STOP` without any extras: that is when it is stopped by the
system.

## Examples

### Start a password-protected view-only server on port 5901

Using `adb shell am` syntax:

```shell
adb shell am start-foreground-service \
 -n com.auodplus.satis.fly/.MainService \
 -a com.auodplus.satis.fly.ACTION_START \
 --es com.auodplus.satis.fly.EXTRA_ACCESS_KEY de32550a6efb43f8a5d145e6c07b2cde \
 --es com.auodplus.satis.fly.EXTRA_REQUEST_ID abc123 \
 --ei com.auodplus.satis.fly.EXTRA_PORT 5901 \
 --es com.auodplus.satis.fly.EXTRA_PASSWORD supersecure \
 --ez com.auodplus.satis.fly.EXTRA_VIEW_ONLY true
```

### Start a server with defaults from Tasker

- Tasker action-category in menu is System -> Send Intent
- In there:
  - Action `com.auodplus.satis.fly.ACTION_START`
  - Extra `com.auodplus.satis.fly.EXTRA_ACCESS_KEY:<your api key from DroidVNC-NG start screen>`
  - Package `com.auodplus.satis.fly`
  - Class `com.auodplus.satis.fly.MainService`
  - Target: Service

### Start a server with defaults from a Kotlin app

- For apps targeting API level 30+, you'll need to specify that your app is able to see/use
  droidVNC-NG. You do this by adding the following snippet to your AndroidManifest.xml, right under 
  the `<manifest>` namepace:
```xml
<queries>
    <package android:name="com.auodplus.satis.fly" />
</queries>
```

- In your Kotlin code, it's then:
```kotlin
val intent = Intent()
intent.setComponent(ComponentName("com.auodplus.satis.fly", "com.auodplus.satis.fly.MainService"))
intent.setAction("com.auodplus.satis.fly.ACTION_START")
intent.putExtra("com.auodplus.satis.fly.EXTRA_ACCESS_KEY", "<your api key from DroidVNC-NG start screen>")
startForegroundService(intent)
```

### Make an outbound connection to a listening viewer from the running server

For example from Java code:

See [MainActivity.java](../app/src/main/java/com/auodplus/satis/fly/MainActivity.java).

### Stop the server again

Using `adb shell am` syntax again:

```shell
adb shell am start-foreground-service \
 -n com.auodplus.satis.fly/.MainService \
 -a com.auodplus.satis.fly.ACTION_STOP \
 --es com.auodplus.satis.fly.EXTRA_ACCESS_KEY de32550a6efb43f8a5d145e6c07b2cde \
 --es com.auodplus.satis.fly.EXTRA_REQUEST_ID def456
```
