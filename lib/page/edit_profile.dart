import 'package:agor/controller.dart';
import 'package:agor/services/database.dart';
import 'package:agor/theme/color.dart';
import 'package:agor/widget/textfield.dart';
import 'package:cosmos/cosmos.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agor/services/cloudinary.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? previewImageUrl;
  List<String> selectedTags = [];
  bool isOnVacation = false;

  @override
  void initState() {
    super.initState();
    biyo.text = Database.profileBio.value;
    _loadUserTags();
    _loadVacationMode();
  }

  Future<void> _loadUserTags() async {
    String uid = await CosmosFirebase.getUID();
    List? tags = await CosmosFirebase.get('tags/"$uid"', true);
    if (tags != null && tags.isNotEmpty) {
      setState(() {
        selectedTags = List<String>.from(tags.sublist(1));
      });
    }
  }

  Future<void> _loadVacationMode() async {
    String uid = await CosmosFirebase.getUID();
    List userData = await CosmosFirebase.get('users/"$uid"', true);
    if (userData.length > 9) {
      setState(() {
        isOnVacation = userData[9] == "1";
      });
    }
  }

  Future<void> _saveTags() async {
    String uid = await CosmosFirebase.getUID();
    String tagId = CosmosRandom.randomTag();
    List<String> tagsToSave = [tagId, ...selectedTags];
    await CosmosFirebase.add(
      reference: "tags",
      tag: uid,
      value: tagsToSave,
    );
  }

  Widget _buildProfilePhoto() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: cColor,
          backgroundImage: NetworkImage(
            previewImageUrl ?? Database.profilePhoto.value,
          ),
          child: (previewImageUrl ?? Database.profilePhoto.value).isEmpty
              ? Icon(Icons.person, size: 50, color: textColor)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () async {
              String? imageUrl = await pickAndUploadImage();
              if (imageUrl != null) {
                setState(() {
                  previewImageUrl = imageUrl;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: defaultColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                color: bg,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    final categories = [
      "İlişki Sorunları",
      "Ayrılık",
      "İş Sorunları",
      "Sinir ve Stres",
      "Aile İçi Sorunlar",
      "Çevre Baskısı",
      "Düşünceler",
      "Maddi Sorunlar",
      "Diğer",
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uzmanlık Alanları',
            style: GoogleFonts.poppins(
              color: defaultColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final isSelected = selectedTags.contains(category);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedTags.remove(category);
                    } else {
                      selectedTags.add(category);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? defaultColor : cColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? defaultColor : borderColor,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? bg : textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profili Düzenle',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 18,
          ),
        ),
        actions: [
          if (previewImageUrl != null)
            TextButton(
              onPressed: () {
                setState(() {
                  previewImageUrl = null;
                });
              },
              child: Text(
                'İptal',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          TextButton(
            onPressed: () async {
              String uid = await CosmosFirebase.getUID();
              List current = await CosmosFirebase.get('users/"$uid"', true);

              if (previewImageUrl != null) {
                current[3] = previewImageUrl;
              }

              current[4] = biyo.text;

              // Tatil modu durumunu güncelle
              if (current.length <= 9) {
                current.add(isOnVacation ? "1" : "0");
              } else {
                current[9] = isOnVacation ? "1" : "0";
              }

              await CosmosFirebase.add(
                reference: "users",
                tag: uid,
                value: current,
                onSuccess: () async {
                  await _saveTags();
                  Navigator.pop(context);
                  Database.getMyProfile();
                },
              );
            },
            child: Text(
              'Kaydet',
              style: GoogleFonts.poppins(
                color: defaultColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfilePhoto(),
            const SizedBox(height: 24),
            TextFieldTT(
              text: "Biyografi",
              controller: biyo,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesap Bilgileri',
                    style: GoogleFonts.poppins(
                      color: defaultColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Kullanıcı Adı', Database.profileName.value),
                  _buildInfoRow('E-posta', Database.profileEmail.value),
                  _buildInfoRow(
                    'Katılma Tarihi',
                    CosmosTime.getDateTR(
                      CosmosTime.getDateTime(Database.profileTime.value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (Database.profileUserType.value == "Dinleyici") ...[
              _buildTagsSection(),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tatil Modu',
                          style: GoogleFonts.poppins(
                            color: defaultColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: isOnVacation,
                          onChanged: (value) {
                            setState(() {
                              isOnVacation = value;
                            });
                          },
                          activeColor: defaultColor,
                        ),
                      ],
                    ),
                    Text(
                      'Tatil modunu açtığınızda, aktif dinleyiciler listesinde görünmezsiniz.',
                      style: TextStyle(
                        color: textColorSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColorSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
