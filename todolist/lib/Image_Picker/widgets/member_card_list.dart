import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MemberCardList extends StatefulWidget {
  @override
  _MemberCardListState createState() => _MemberCardListState();
}

class _MemberCardListState extends State<MemberCardList> {
  final List<Map<String, dynamic>> members = [
    {"name": "Nguyễn Văn A", "role": "Leader", "avatar": null},
    {"name": "Trần Thị B", "role": "Member", "avatar": null},
    {"name": "Lê Văn C", "role": "Member", "avatar": null},
  ];

  final ImagePicker _picker = ImagePicker();

  void _changeAvatar(int index) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Chọn ảnh đại diện"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Row(
              children: [
                Icon(Icons.camera_alt),
                SizedBox(width: 8),
                Text("Chụp ảnh"),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Row(
              children: [
                Icon(Icons.photo),
                SizedBox(width: 8),
                Text("Chọn từ thư viện"),
              ],
            ),
          ),
        ],
      ),
    );

    if (source != null) {
      final XFile? pickedFile =
      await _picker.pickImage(source: source, maxWidth: 800);
      if (pickedFile != null) {
        setState(() {
          members[index]["avatar"] = File(pickedFile.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cột
        childAspectRatio: 0.8, // chỉnh tỷ lệ cho đẹp
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _changeAvatar(index),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: member["avatar"] != null
                        ? FileImage(member["avatar"])
                        : null,
                    child: member["avatar"] == null
                        ? Text(
                      member["name"][0],
                      style: const TextStyle(fontSize: 24),
                    )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    member["name"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    member["role"],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
