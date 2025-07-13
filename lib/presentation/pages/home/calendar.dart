import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:pet_moment/presentation/pages/home/polaroid_detail.dart';
import 'package:table_calendar/table_calendar.dart';

class AlbumCalendarView extends StatefulWidget {
  final double containerWidth;
  final double containerHeight;
  final Map<DateTime, List<Map<String, dynamic>>> polaroidEntries;
  final bool isLoading;
  final String userId;
  final String albumId;
  final VoidCallback? onDataChanged;

  AlbumCalendarView({
    Key? key,
    required this.containerWidth,
    required this.containerHeight,
    required this.polaroidEntries,
    required this.isLoading,
    required this.userId,
    required this.albumId,
    required this.onDataChanged, // 콜백 초기화
  }) : super(key: key);

  @override
  State<AlbumCalendarView> createState() => _AlbumCalendarViewState();
}

class _AlbumCalendarViewState extends State<AlbumCalendarView> {
  DateTime? _selectedDate;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  @override
  void didUpdateWidget(covariant AlbumCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 부모에서 polaroidEntries가 새 Map으로 교체되면 강제 리빌드
    if (oldWidget.polaroidEntries != widget.polaroidEntries) {
      setState(() {});
    }
  }

  void _showPolaroidCarousel(DateTime date) {
    final compareDate = DateTime(date.year, date.month, date.day);
    final polaroids = widget.polaroidEntries[compareDate];
    if (polaroids == null || polaroids.isEmpty) return;
    int currentIndex = 0;
    final polaroidWidgets = polaroids.map((polaroid) {
      return PolaroidDetail(
        key: ValueKey(polaroid['id']),
        userId: widget.userId,
        albumId: widget.albumId,
        polaroidId: polaroid['id'],
        isCalendarView: true,
      );
    }).toList();
    // 다이얼로그를 표시하고 결과값 처리
    showGeneralDialog<bool>(
      // 반환 타입 추가
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.98,
                          height: MediaQuery.of(context).size.height * 0.75,
                          child: CarouselSlider(
                            items: polaroidWidgets,
                            options: CarouselOptions(
                              height: double.infinity,
                              enlargeCenterPage: false,
                              enableInfiniteScroll: false,
                              viewportFraction: 1.0,
                              onPageChanged: (index, reason) {
                                if (currentIndex != index) {
                                  setState(() => currentIndex = index);
                                }
                              },
                            ),
                          ),
                        ),
                        _buildCarouselIndicator(polaroids.length, currentIndex),
                      ],
                    ),
                    Positioned(
                      top: -10,
                      right: 10,
                      child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => Navigator.of(context)
                              .pop(false)), // 그냥 닫을 때는 false 반환
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).then((bool? wasChanged) {
      // 다이얼로그의 결과 처리
      if (wasChanged == true) {
        // 부모 위젯에 데이터 새로고침 요청
        widget.onDataChanged?.call();

        // 이 위젯도 강제로 다시 빌드
        setState(() {});
      }
    });
  }

  Widget _buildCarouselIndicator(int itemCount, int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime date, {bool isOutside = false}) {
    final compareDate = DateTime(date.year, date.month, date.day);
    final polaroids = widget.polaroidEntries[compareDate];
    final hasImage = polaroids != null && polaroids.isNotEmpty;
    final isToday = isSameDay(date, DateTime.now());
    //final isSelected = _selectedDate != null && isSameDay(date, _selectedDate!);
    final textColor = isOutside ? Colors.grey : Colors.black;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        if (hasImage) _showPolaroidCarousel(date);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: const Color(0xFFD76F69), width: 3)
              : null,
          color: Colors.transparent,
        ),
        child: hasImage
            ? Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image:
                        CachedNetworkImageProvider(polaroids.first['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
              ),
      ),
    );
  }

  Widget _buildSpiralDecoration() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        7,
        (index) => Image.asset('assets/sp.png', width: 30, height: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * 0.9;
        final maxHeight = constraints.maxHeight * 0.8;
        final spiralTop = constraints.maxHeight * 0.09;
        final spiralHorizontal = constraints.maxWidth * 0.05;
        final cellSize = (maxWidth - 14) / 7;
        final screenW = MediaQuery.of(context).size.width;
        final screenH = MediaQuery.of(context).size.height;

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/gradient.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: spiralTop - 10,
              left: spiralHorizontal,
              right: spiralHorizontal,
              child: _buildSpiralDecoration(),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom > 100
                      ? MediaQuery.of(context).viewInsets.bottom - 100
                      : 50,
                ),
                child: Container(
                  height: widget.containerHeight,
                  width: widget.containerWidth,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.transparent, Colors.transparent],
                    ),
                    border: Border.all(color: Colors.grey, width: 2.0),
                  ),
                  child: widget.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            SizedBox(height: widget.containerHeight * 0.1),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: widget.containerWidth * 0.05),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: () {
                                      setState(() {
                                        _focusedDay = DateTime(_focusedDay.year,
                                            _focusedDay.month - 1);
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${_focusedDay.year}',
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${_focusedDay.month}월',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () {
                                      setState(() {
                                        _focusedDay = DateTime(_focusedDay.year,
                                            _focusedDay.month + 1);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: widget.containerHeight * 0.04),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenW * 0.05),
                                child: TableCalendar(
                                  firstDay: DateTime(2000),
                                  lastDay: DateTime(2100),
                                  focusedDay: _focusedDay,
                                  calendarFormat: _calendarFormat,
                                  eventLoader: (day) {
                                    final key =
                                        DateTime(day.year, day.month, day.day);
                                    return widget.polaroidEntries[key] ?? [];
                                  },
                                  selectedDayPredicate: (day) =>
                                      isSameDay(_selectedDate, day),
                                  headerVisible: false,
                                  daysOfWeekStyle: const DaysOfWeekStyle(
                                    weekdayStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                    weekendStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedDate = selectedDay;
                                      _focusedDay = focusedDay;
                                    });
                                    final compareDate = DateTime(
                                        selectedDay.year,
                                        selectedDay.month,
                                        selectedDay.day);
                                    if (widget.polaroidEntries
                                        .containsKey(compareDate)) {
                                      _showPolaroidCarousel(selectedDay);
                                    }
                                  },
                                  calendarStyle: const CalendarStyle(
                                    outsideDaysVisible: true,
                                    cellMargin: EdgeInsets.all(2),
                                  ),
                                  calendarBuilders: CalendarBuilders(
                                    defaultBuilder: (context, date, _) =>
                                        _buildCalendarCell(date),
                                    selectedBuilder: (context, date, _) =>
                                        _buildCalendarCell(date),
                                    todayBuilder: (context, date, _) =>
                                        _buildCalendarCell(date),
                                    outsideBuilder: (context, date, _) =>
                                        _buildCalendarCell(date,
                                            isOutside: true),
                                    markerBuilder: (context, date, events) {
                                      return const SizedBox(); // 마커를 아예 안 보이게 처리
                                    },
                                  ),
                                  availableCalendarFormats: const {
                                    CalendarFormat.month: '월'
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
