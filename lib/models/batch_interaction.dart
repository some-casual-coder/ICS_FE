import 'package:fliccsy/models/batch_swipe.dart';

class BatchInteraction {
  final String userId;
  final String? roomId;
  final List<BatchSwipe> swipes;

  BatchInteraction({
    required this.userId,
    this.roomId,
    required this.swipes,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        if (roomId != null) 'room_id': roomId,
        'swipes': swipes.map((swipe) => swipe.toJson()).toList(),
      };
}
