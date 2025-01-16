import 'package:fliccsy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomListDialog extends StatefulWidget {
  final List<Map<String, dynamic>> rooms;
  final Function(String) onJoinRoom;

  const RoomListDialog({
    Key? key,
    required this.rooms,
    required this.onJoinRoom,
  }) : super(key: key);

  @override
  State<RoomListDialog> createState() => _RoomListDialogState();
}

class _RoomListDialogState extends State<RoomListDialog> {
  String? joiningRoomCode;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                'Available Rooms',
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  color: AppColors.darkAccent,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 100,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.rooms.length,
                separatorBuilder: (context, index) => CustomDivider(),
                itemBuilder: (context, index) {
                  final room = widget.rooms[index];
                  final isJoining = joiningRoomCode == room['code'];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${room['name']} (${room['code']})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${room['user_count']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Text(
                          ' | ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '${room['distance'].toStringAsFixed(1)} km away',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: isJoining
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                    onTap:
                        isJoining ? null : () => _handleJoinRoom(room['code']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget CustomDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth * 0.7,
            child: CustomPaint(
              painter: DottedLinePainter(color: AppColors.primary),
              child: const SizedBox(height: 1),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleJoinRoom(String roomCode) async {
    setState(() {
      joiningRoomCode = roomCode;
    });
    try {
      await widget.onJoinRoom(roomCode);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Join request sent, waiting for host approval...',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: const EdgeInsets.only(
              bottom: 16,
              left: 16,
              right: 16,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join room'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          joiningRoomCode = null;
        });
      }
    }
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const double dashWidth = 4;
    const double dashSpace = 4;
    double currentX = 0;

    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(currentX + dashWidth, 0),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
