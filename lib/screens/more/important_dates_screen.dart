import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ipo_provider.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../ipos/ipo_detail_screen.dart';
import '../../models/ipo.dart';

class _IpoEvent {
  final DateTime date;
  final String dateIso;
  final String eventType; // IPO Opens, IPO Closes, Allotment Date, Listing Date
  final Ipo ipo;

  _IpoEvent({
    required this.date,
    required this.dateIso,
    required this.eventType,
    required this.ipo,
  });
}

class ImportantDatesScreen extends StatelessWidget {
  const ImportantDatesScreen({super.key});

  List<_IpoEvent> _collectEvents(List<Ipo> ipos) {
    final events = <_IpoEvent>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var ipo in ipos) {
      void addEvent(String? dateIso, String type) {
        if (dateIso == null || dateIso.isEmpty) return;
        final dt = AppDateUtils.parseDate(dateIso);
        if (dt != null) {
          final dayOnly = DateTime(dt.year, dt.month, dt.day);
          // Only show today and future events
          if (!dayOnly.isBefore(today)) {
            events.add(_IpoEvent(
              date: dayOnly,
              dateIso: dateIso,
              eventType: type,
              ipo: ipo,
            ));
          }
        }
      }

      addEvent(ipo.openDate, 'IPO Opens');
      addEvent(ipo.closeDate, 'IPO Closes');
      addEvent(ipo.allotmentDate, 'Allotment Expected');
      addEvent(ipo.listingDate, 'Listing Date');
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final ipoProvider = Provider.of<IpoProvider>(context);
    final events = _collectEvents(ipoProvider.allIpos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Important IPO Dates'),
      ),
      body: events.isEmpty
          ? const EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No Upcoming Events',
              message: 'Upcoming IPO open, close, allotment, and listing dates will appear here automatically.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isToday = AppDateUtils.isToday(event.date);
                final isTomorrow = AppDateUtils.isTomorrow(event.date);

                Color eventColor;
                if (event.eventType == 'IPO Opens') {
                  eventColor = Colors.green;
                } else if (event.eventType == 'IPO Closes') {
                  eventColor = Colors.red;
                } else if (event.eventType == 'Allotment Expected') {
                  eventColor = Colors.purple;
                } else {
                  eventColor = Colors.blue;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IpoDetailScreen(ipo: event.ipo),
                        ),
                      );
                    },
                    leading: Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.green.withOpacity(0.2)
                            : Theme.of(context).primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppDateUtils.formatShortDate(event.date),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.green[900] : Theme.of(context).primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.ipo.companyName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          )
                        else if (isTomorrow)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TOMORROW',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: eventColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.eventType,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: eventColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}
