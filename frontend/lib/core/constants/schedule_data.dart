class DaySchedule {
  final String dayName;
  final List<String> provinces;
  const DaySchedule({required this.dayName, required this.provinces});
}

class ScheduleData {
  static const schedule = {
    1: DaySchedule(dayName: 'Thứ Hai', provinces: ['Hà Nội']),
    2: DaySchedule(dayName: 'Thứ Ba', provinces: ['Quảng Ninh']),
    3: DaySchedule(dayName: 'Thứ Tư', provinces: ['Bắc Ninh']),
    4: DaySchedule(dayName: 'Thứ Năm', provinces: ['Hà Nội']),
    5: DaySchedule(dayName: 'Thứ Sáu', provinces: ['Hải Phòng']),
    6: DaySchedule(dayName: 'Thứ Bảy', provinces: ['Nam Định']),
    7: DaySchedule(dayName: 'Chủ Nhật', provinces: ['Thái Bình']),
  };
  static Map<int, DaySchedule> forRegion(String regionKey) => schedule;
}
