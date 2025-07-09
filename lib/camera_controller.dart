import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class CameraController extends GetxController {
  final TextEditingController ipController = TextEditingController();

  final RxString streamUrl = ''.obs;
  final RxBool isConnected = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool flashState = false.obs;

  Timer? _connectionTimer;

  @override
  void onInit() {
    super.onInit();
    // Set default IP for testing
    ipController.text = '192.168.1.100';
  }

  @override
  void onClose() {
    _connectionTimer?.cancel();
    ipController.dispose();
    super.onClose();
  }

  Future<void> connectToCamera() async {
    String ip = ipController.text.trim();

    if (ip.isEmpty) {
      Get.snackbar('Error', 'Please enter IP address');
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Test connection first
      final response = await http.get(
        Uri.parse('http://$ip/status'),
        headers: {'Connection': 'close'},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Parse status response
        final statusData = json.decode(response.body);
        flashState.value = statusData['flash_state'] == 'on';

        streamUrl.value = 'http://$ip/stream';
        isConnected.value = true;
        errorMessage.value = '';

        // Start periodic connection check
        _startConnectionCheck();

        Get.snackbar(
          'Success',
          'Connected to ESP32-CAM',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Camera not responding');
      }
    } catch (e) {
      isConnected.value = false;
      streamUrl.value = '';
      errorMessage.value = 'Failed to connect: ${e.toString()}';

      Get.snackbar(
        'Connection Error',
        'Could not connect to ESP32-CAM. Check IP address and network.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _startConnectionCheck() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    if (streamUrl.value.isEmpty) return;

    try {
      String ip = ipController.text.trim();
      final response = await http.get(
        Uri.parse('http://$ip/status'),
        headers: {'Connection': 'close'},
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final statusData = json.decode(response.body);
        flashState.value = statusData['flash_state'] == 'on';

        if (!isConnected.value) {
          isConnected.value = true;
          errorMessage.value = '';
        }
      } else {
        throw Exception('Connection lost');
      }
    } catch (e) {
      isConnected.value = false;
      errorMessage.value = 'Connection lost';
    }
  }

  void refreshStream() {
    if (streamUrl.value.isNotEmpty) {
      String currentUrl = streamUrl.value;
      streamUrl.value = '';
      Future.delayed(Duration(milliseconds: 100), () {
        streamUrl.value = currentUrl;
      });
    } else {
      connectToCamera();
    }
  }

  void disconnect() {
    _connectionTimer?.cancel();
    streamUrl.value = '';
    isConnected.value = false;
    errorMessage.value = '';
    flashState.value = false;
  }

  Future<void> toggleFlash() async {
    if (!isConnected.value) return;

    String ip = ipController.text.trim();
    String newState = flashState.value ? 'off' : 'on';

    try {
      final response = await http.get(
        Uri.parse('http://$ip/flash?state=$newState'),
        headers: {'Connection': 'close'},
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        flashState.value = responseData['flash_state'] == 'on';

        Get.snackbar(
          'Flash Control',
          'Flash ${flashState.value ? 'ON' : 'OFF'}',
          backgroundColor: flashState.value ? Colors.orange : Colors.grey,
          colorText: Colors.white,
          duration: Duration(seconds: 1),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to control flash: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
