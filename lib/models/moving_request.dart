class RoomInfo {
  final String name;
  int boxCount;
  List<String> imagePaths;

  RoomInfo({required this.name, this.boxCount = 0, List<String>? imagePaths})
      : imagePaths = imagePaths ?? [];
}

class MovingRequest {
  // Step 1 - 기본 정보
  String name;
  String phone;
  String moveDate;
  String fromAddress;
  String toAddress;

  // Step 2 - 집 정보
  double houseSize;       // 평수
  int roomCount;          // 방 개수 (1~6)
  int livingRoomCount;    // 거실 개수 (1~2)
  bool hasVeranda;
  bool hasElevator;

  // Step 3 - 방별 정보
  List<RoomInfo> rooms;

  String memo;

  MovingRequest({
    this.name = '',
    this.phone = '',
    this.moveDate = '',
    this.fromAddress = '',
    this.toAddress = '',
    this.houseSize = 0,
    this.roomCount = 1,
    this.livingRoomCount = 1,
    this.hasVeranda = false,
    this.hasElevator = false,
    List<RoomInfo>? rooms,
    this.memo = '',
  }) : rooms = rooms ?? [];

  void buildRooms() {
    rooms.clear();
    for (int i = 1; i <= roomCount; i++) {
      rooms.add(RoomInfo(name: '방 $i'));
    }
    for (int i = 1; i <= livingRoomCount; i++) {
      rooms.add(RoomInfo(
          name: livingRoomCount == 1 ? '거실' : '거실 $i'));
    }
    rooms.add(RoomInfo(name: '주방'));
    if (hasVeranda) rooms.add(RoomInfo(name: '베란다'));
  }

  int get totalBoxes => rooms.fold(0, (sum, r) => sum + r.boxCount);

  // 평수 기반 + 입력값 기반 추정
  int get estimatedBoxes {
    final byInput = totalBoxes;
    if (byInput > 0) return byInput;
    return (houseSize * 0.8).round();
  }

  // 이사 차량 추정
  String get truckEstimate {
    final boxes = estimatedBoxes;
    if (boxes <= 30) return '1톤 트럭 1대';
    if (boxes <= 60) return '2.5톤 트럭 1대';
    if (boxes <= 100) return '5톤 트럭 1대';
    return '5톤 트럭 2대 이상';
  }
}
