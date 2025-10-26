import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../Image_Picker/screens/members_screen.dart';
import '../../models.dart';


class MembersScreen extends StatefulWidget {
  final Project project;
  final VoidCallback onUpdate;

  const MembersScreen({
    super.key,
    required this.project,
    required this.onUpdate,
  });

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _addMember() async {
    String name = '';
    String role = '';
    File? avatar;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Thêm thành viên"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final XFile? picked =
                  await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() {
                      avatar = File(picked.path);
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: avatar != null ? FileImage(avatar!) : null,
                  child: avatar == null ? const Icon(Icons.add_a_photo) : null,
                ),
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Tên"),
                onChanged: (val) => name = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Vai trò"),
                onChanged: (val) => role = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.trim().isEmpty) return;
                setState(() {
                  widget.project.members.add(
                    Member(name: name, role: role, avatar: avatar, id: ''),
                  );
                });
                widget.onUpdate();
                Navigator.pop(ctx);
              },
              child: const Text("Thêm"),
            ),
          ],
        );
      },
    );
  }

  void _changeAvatar(int index) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Chọn ảnh đại diện"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Row(
              children: [Icon(Icons.camera_alt), SizedBox(width: 8), Text("Chụp ảnh")],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Row(
              children: [Icon(Icons.photo), SizedBox(width: 8), Text("Chọn từ thư viện")],
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
          widget.project.members[index].avatar = File(pickedFile.path);
        });
        widget.onUpdate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.project.members;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thành viên"),
      ),
      body: members.isEmpty
          ? CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: isSmallScreen ? 40 : 56,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có thành viên nào',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Nhấn "+" để bắt đầu',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return Card(
            elevation: 2,
            child: ListTile(
              leading: GestureDetector(
                onTap: () => _changeAvatar(index),
                child: CircleAvatar(
                  backgroundImage: member.avatar != null
                      ? FileImage(member.avatar!)
                      : null,
                  child: member.avatar == null
                      ? Text(member.name.isNotEmpty
                      ? member.name[0].toUpperCase()
                      : '?')
                      : null,
                ),
              ),
              title: Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                member.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMember,
        child: const Icon(Icons.add),
      ),
    );
  }
}
