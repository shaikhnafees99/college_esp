import 'package:college_esp/camera_controller.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ESP32-CAM Stream',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraStreamPage(),
    );
  }
}

class CameraStreamPage extends StatelessWidget {
  final CameraController controller = Get.put(CameraController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP32-CAM Stream'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.refreshStream(),
          ),
        ],
      ),
      body: Column(
        children: [
          // IP Address Input
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.ipController,
                    decoration: InputDecoration(
                      labelText: 'ESP32-CAM IP Address',
                      hintText: '192.168.1.100',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => controller.connectToCamera(),
                  child: Text('Connect'),
                ),
              ],
            ),
          ),
          // Stream Display
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.refreshStream(),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.streamUrl.value.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Enter ESP32-CAM IP address and connect',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                width: double.infinity,
                height: double.infinity,
                child: Image.network(
                  controller.streamUrl.value,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load stream',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          // Controls Section
          Container(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Flash Control
                Obx(() => ElevatedButton.icon(
                      onPressed: controller.isConnected.value
                          ? () => controller.toggleFlash()
                          : null,
                      icon: Icon(
                        controller.flashState.value
                            ? Icons.flash_on
                            : Icons.flash_off,
                      ),
                      label: Text(controller.flashState.value
                          ? 'Flash ON'
                          : 'Flash OFF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.flashState.value
                            ? Colors.orange
                            : Colors.grey,
                      ),
                    )),
                // Refresh Button
                ElevatedButton.icon(
                  onPressed: controller.isConnected.value
                      ? () => controller.refreshStream()
                      : null,
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                ),
              ],
            ),
          ),
          // Connection Status
          Obx(() => Container(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      controller.isConnected.value
                          ? Icons.wifi
                          : Icons.wifi_off,
                      color: controller.isConnected.value
                          ? Colors.green
                          : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      controller.isConnected.value
                          ? 'Connected'
                          : 'Disconnected',
                      style: TextStyle(
                        color: controller.isConnected.value
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
