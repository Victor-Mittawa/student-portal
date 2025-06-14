import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentUploadScreen extends StatefulWidget {
  const PaymentUploadScreen({super.key});

  @override
  State<PaymentUploadScreen> createState() => _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends State<PaymentUploadScreen> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _uploadStatus;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _uploadStatus = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _uploadStatus = 'User not authenticated.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading...';
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('payment_proofs')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}');

      final uploadTask = await storageRef.putData(_selectedFile!.bytes!);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save to Firestore
      await FirebaseFirestore.instance.collection('students').doc(user.uid).update({
        'paymentProofUrl': downloadUrl,
        'paymentUploadedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _uploadStatus = 'Upload successful!';
        _selectedFile = null;
      });
    } catch (e) {
      setState(() => _uploadStatus = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Payment Proof')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Select File'),
            ),
            const SizedBox(height: 10),
            if (_selectedFile != null) Text('Selected: ${_selectedFile!.name}'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadFile,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload'),
            ),
            const SizedBox(height: 20),
            if (_uploadStatus != null)
              Text(
                _uploadStatus!,
                style: TextStyle(
                  color: _uploadStatus!.startsWith('Error') ? Colors.red : Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
