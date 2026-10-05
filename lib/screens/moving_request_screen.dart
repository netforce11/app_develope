import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/moving_request.dart';

class MovingRequestScreen extends StatefulWidget {
  const MovingRequestScreen({super.key});

  @override
  State<MovingRequestScreen> createState() => _MovingRequestScreenState();
}

class _MovingRequestScreenState extends State<MovingRequestScreen> {
  int _currentStep = 0; // 0:기본정보 1:집정보 2:방별짐 3:완료
  final _formKey1 = GlobalKey<FormState>();
  final _request = MovingRequest();

  // Step1 컨트롤러
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  // Step2 컨트롤러
  final _sizeCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _request.moveDate =
            '${picked.year}년 ${picked.month}월 ${picked.day}일';
      });
    }
  }

  // ── Step 이동 ──────────────────────────────────────────────────
  void _nextFromStep1() {
    if (!_formKey1.currentState!.validate()) return;
    if (_request.moveDate.isEmpty) {
      _showSnackBar('이사 날짜를 선택해주세요.');
      return;
    }
    _request.name = _nameCtrl.text;
    _request.phone = _phoneCtrl.text;
    _request.fromAddress = _fromCtrl.text;
    _request.toAddress = _toCtrl.text;
    setState(() => _currentStep = 1);
  }

  void _nextFromStep2() {
    if (_sizeCtrl.text.isEmpty) {
      _showSnackBar('집 평수를 입력해주세요.');
      return;
    }
    _request.houseSize = double.tryParse(_sizeCtrl.text) ?? 0;
    _request.buildRooms();
    setState(() => _currentStep = 2);
  }

  void _nextFromStep3() {
    setState(() => _currentStep = 3);
  }

  void _goBack() {
    if (_currentStep > 0) setState(() => _currentStep--);
    else Navigator.pop(context);
  }

  // ── 사진 선택 ──────────────────────────────────────────────────
  Future<void> _pickImages(RoomInfo room) async {
    if (room.imagePaths.length >= 5) {
      _showSnackBar('방당 사진은 최대 5장까지 등록할 수 있어요.');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      final remaining = 5 - room.imagePaths.length;
      final picked =
          result.paths.whereType<String>().take(remaining).toList();
      setState(() => room.imagePaths.addAll(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(['기본 정보', '집 정보', '방별 짐 등록', '신청 완료'][_currentStep]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _goBack,
        ),
      ),
      body: [
        _buildStep1(),
        _buildStep2(),
        _buildStep3(),
        _buildStep4(),
      ][_currentStep],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Step 1: 기본 정보
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIndicator(current: 1, total: 4),
            const SizedBox(height: 24),
            const _SectionTitle('기본 정보'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: '이름',
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '이름을 입력해주세요' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                  labelText: '연락처',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '01000000000'),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return '연락처를 입력해주세요';
                if (v.length < 10) return '올바른 연락처를 입력해주세요';
                return null;
              },
            ),
            const SizedBox(height: 24),
            const _SectionTitle('이사 날짜'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF4A90D9)),
                    const SizedBox(width: 12),
                    Text(
                      _request.moveDate.isEmpty
                          ? '날짜를 선택하세요'
                          : _request.moveDate,
                      style: TextStyle(
                        fontSize: 16,
                        color: _request.moveDate.isEmpty
                            ? Colors.grey[400]
                            : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('이사 주소'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fromCtrl,
              decoration: const InputDecoration(
                  labelText: '출발지 (현재 주소)',
                  prefixIcon: Icon(Icons.location_on_outlined)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '출발지를 입력해주세요' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _toCtrl,
              decoration: const InputDecoration(
                  labelText: '도착지 (이사할 주소)',
                  prefixIcon: Icon(Icons.flag_outlined)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '도착지를 입력해주세요' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _nextFromStep1,
              child: const Text('다음 →', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Step 2: 집 정보
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 2, total: 4),
          const SizedBox(height: 24),

          // 평수
          const _SectionTitle('집 평수'),
          const SizedBox(height: 12),
          TextField(
            controller: _sizeCtrl,
            decoration: const InputDecoration(
              labelText: '평수 입력',
              prefixIcon: Icon(Icons.home_outlined),
              suffixText: '평',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
          ),
          const SizedBox(height: 24),

          // 엘리베이터
          const _SectionTitle('엘리베이터'),
          const SizedBox(height: 8),
          _ToggleCard(
            label: '엘리베이터 사용 가능',
            icon: Icons.elevator_outlined,
            value: _request.hasElevator,
            onChanged: (v) => setState(() => _request.hasElevator = v),
          ),
          const SizedBox(height: 24),

          // 방 개수
          const _SectionTitle('방 개수'),
          const SizedBox(height: 12),
          _CountSelector(
            value: _request.roomCount,
            min: 1,
            max: 6,
            onChanged: (v) => setState(() => _request.roomCount = v),
          ),
          const SizedBox(height: 24),

          // 거실 개수
          const _SectionTitle('거실 개수'),
          const SizedBox(height: 12),
          _CountSelector(
            value: _request.livingRoomCount,
            min: 1,
            max: 2,
            onChanged: (v) =>
                setState(() => _request.livingRoomCount = v),
          ),
          const SizedBox(height: 24),

          // 베란다
          const _SectionTitle('베란다'),
          const SizedBox(height: 8),
          _ToggleCard(
            label: '베란다 있음',
            icon: Icons.balcony_outlined,
            value: _request.hasVeranda,
            onChanged: (v) => setState(() => _request.hasVeranda = v),
          ),
          const SizedBox(height: 32),

          // 미리보기
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90D9).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF4A90D9).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('등록될 공간',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ...List.generate(
                        _request.roomCount,
                        (i) => _RoomChip(
                            label: '방 ${i + 1}',
                            color: const Color(0xFF4A90D9))),
                    ...List.generate(
                        _request.livingRoomCount,
                        (i) => _RoomChip(
                            label: _request.livingRoomCount == 1
                                ? '거실'
                                : '거실 ${i + 1}',
                            color: Colors.orange)),
                    _RoomChip(label: '주방', color: Colors.green),
                    if (_request.hasVeranda)
                      _RoomChip(label: '베란다', color: Colors.purple),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextFromStep2,
            child: const Text('다음 →', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Step 3: 방별 짐 등록
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 3, total: 4),
          const SizedBox(height: 8),
          Text(
            '각 공간별 사진과 예상 박스 수를 입력해주세요',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 20),
          ..._request.rooms.map((room) => _RoomCard(
                room: room,
                onPickImages: () => _pickImages(room),
                onRemoveImage: (i) =>
                    setState(() => room.imagePaths.removeAt(i)),
                onBoxCountChanged: (v) =>
                    setState(() => room.boxCount = v),
              )),
          const SizedBox(height: 16),
          // 실시간 합계
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('현재 입력 총 박스 수',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${_request.totalBoxes}박스',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90D9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextFromStep3,
            child: const Text('결과 보기 →',
                style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Step 4: 완료 & 추정 결과
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep4() {
    final estimated = _request.estimatedBoxes;
    final rooms = _request.rooms;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 4, total: 4),
          const SizedBox(height: 24),

          // 완료 배너
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.green[50], shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle,
                      color: Colors.green, size: 52),
                ),
                const SizedBox(height: 16),
                const Text('신청이 완료되었습니다!',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_request.moveDate,
                    style: const TextStyle(
                        color: Color(0xFF4A90D9),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 이사짐 추정 결과
          const _SectionTitle('이사짐 추정 결과'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('예상 이사 박스',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('$estimated 박스',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '추천 차량: ${_request.truckEstimate}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 방별 상세
          const _SectionTitle('공간별 박스 수'),
          const SizedBox(height: 12),
          ...rooms.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(r.name,
                          style: const TextStyle(fontSize: 15)),
                    ),
                    Text('${r.boxCount}박스',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A90D9))),
                    const SizedBox(width: 8),
                    Text('(사진 ${r.imagePaths.length}장)',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('합계',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${_request.totalBoxes}박스',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF4A90D9))),
            ],
          ),
          const SizedBox(height: 24),

          // 집 정보 요약
          const _SectionTitle('집 정보'),
          const SizedBox(height: 12),
          _InfoCard(children: [
            _InfoRow('평수', '${_request.houseSize.toStringAsFixed(0)}평'),
            _InfoRow('방',
                '${_request.roomCount}개 / 거실 ${_request.livingRoomCount}개'),
            _InfoRow('베란다', _request.hasVeranda ? '있음' : '없음'),
            _InfoRow('엘리베이터', _request.hasElevator ? '가능' : '없음'),
          ]),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () => Navigator.of(context)
                .popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600]),
            child: const Text('홈으로 돌아가기',
                style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── 공통 위젯들 ──────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current, total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i + 1 <= current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 8 : 0),
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF4A90D9)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E)));
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value
          ? const Color(0xFF4A90D9).withOpacity(0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: value
                  ? const Color(0xFF4A90D9)
                  : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: value
                      ? const Color(0xFF4A90D9)
                      : Colors.grey[500]),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          color: value
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey[600]))),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF4A90D9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountSelector extends StatelessWidget {
  final int value, min, max;
  final ValueChanged<int> onChanged;

  const _CountSelector({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: const Color(0xFF4A90D9),
          iconSize: 32,
        ),
        const SizedBox(width: 8),
        Text('$value개',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: const Color(0xFF4A90D9),
          iconSize: 32,
        ),
        Text('(최대 $max개)',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }
}

class _RoomChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RoomChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomInfo room;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final ValueChanged<int> onBoxCountChanged;

  const _RoomCard({
    required this.room,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onBoxCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 방 이름
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined,
                  color: Color(0xFF4A90D9), size: 20),
              const SizedBox(width: 8),
              Text(room.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),

          // 박스 수 입력
          Row(
            children: [
              Text('예상 박스 수',
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 13)),
              const Spacer(),
              IconButton(
                onPressed: room.boxCount > 0
                    ? () => onBoxCountChanged(room.boxCount - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF4A90D9),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text('${room.boxCount}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => onBoxCountChanged(room.boxCount + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF4A90D9),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Text('박스',
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),

          // 사진 영역
          Text('사진 (${room.imagePaths.length}/5)',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...room.imagePaths.asMap().entries.map((e) => Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(File(e.value),
                                fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => onRemoveImage(e.key),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    )),
                if (room.imagePaths.length < 5)
                  GestureDetector(
                    onTap: onPickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: Colors.grey[400], size: 26),
                          Text('사진 추가',
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 14))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14))),
        ],
      ),
    );
  }
}
