import 'package:flutter/material.dart';
import 'hr_letter_view.dart';

class HrLetterListPage extends StatefulWidget {
  const HrLetterListPage({super.key});

  @override
  State<HrLetterListPage> createState() => _HrLetterListPageState();
}

class _HrLetterListPageState extends State<HrLetterListPage> {
  // Premium Design Colors
  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  // Sample HR Letters Data - NOT FINAL because we need to modify isRead status
  List<Map<String, dynamic>> hrLetters = [ // FIXED: Removed underscore and 'final' - this field needs to be mutable
    {
      'id': '1',
      'subject': 'Welcome to EcashBook Solutions',
      'sender': 'HR Department',
      'senderEmail': 'hr@ecashbook.com',
      'date': 'Aug 21, 2025',
      'time': '10:30 AM',
      'content': '''Dear Team Member,

We are delighted to welcome you to EcashBook Solutions! This letter serves as an official welcome and provides you with essential information about your role and our company.

Company Overview:
EcashBook Solutions is a leading financial technology company specializing in employee management and payroll solutions. We pride ourselves on innovation, excellence, and creating value for our clients.

Your Role:
As a valued member of our team, you will be contributing to our mission of revolutionizing workplace management through technology. Your skills and expertise will help us maintain our position as industry leaders.

What to Expect:
- Comprehensive onboarding program
- Access to cutting-edge technology and tools
- Collaborative work environment
- Professional development opportunities
- Competitive benefits package

Next Steps:
1. Complete your onboarding documentation
2. Attend orientation session on your first day
3. Meet with your team lead for role-specific training
4. Set up your workspace and access credentials

We look forward to working with you and seeing the positive impact you'll make on our organization.

Best regards,
HR Department
EcashBook Solutions''',
      'isRead': false, // UNREAD
      'priority': 'high',
    },
    {
      'id': '2',
      'subject': 'Updated Leave Policy - Effective September 2025',
      'sender': 'Policy Team',
      'senderEmail': 'policy@ecashbook.com',
      'date': 'Aug 20, 2025',
      'time': '02:15 PM',
      'content': '''Dear Employees,

We are writing to inform you of important updates to our company leave policy, effective September 1, 2025.

Key Changes:

1. Annual Leave:
- Increased from 20 to 25 days per year
- Can be carried forward up to 5 days to next year
- Advance booking required for leaves exceeding 5 consecutive days

2. Sick Leave:
- Remains at 12 days per year
- Medical certificate required for leaves exceeding 3 consecutive days
- Unused sick leave cannot be carried forward

3. Personal Leave:
- New category introduced: 3 days per year
- Can be used for personal emergencies
- Prior approval from immediate supervisor required

4. Maternity/Paternity Leave:
- Extended to 6 months for maternity leave
- Paternity leave increased to 15 days
- Benefits and salary protection during leave period

5. Application Process:
- All leave applications must be submitted through the EcashBook app
- Minimum 24 hours notice required (except emergencies)
- Auto-approval for leaves up to 2 days (subject to team requirements)

Please review the complete policy document attached to this email. For any questions, contact HR at hr@ecashbook.com.

Thank you for your attention to this matter.

HR Policy Team
EcashBook Solutions''',
      'isRead': true, // READ
      'priority': 'medium',
    },
    {
      'id': '3',
      'subject': 'Annual Performance Review Schedule',
      'sender': 'Performance Team',
      'senderEmail': 'performance@ecashbook.com',
      'date': 'Aug 18, 2025',
      'time': '11:45 AM',
      'content': '''Dear Team,

It's that time of year again! We're excited to announce the schedule for our Annual Performance Review process.

Review Timeline:
- Self-Assessment Submission: September 1-15, 2025
- Manager Review Period: September 16-30, 2025
- HR Review and Calibration: October 1-15, 2025
- Final Review Meetings: October 16-31, 2025

What You Need to Do:

1. Complete Self-Assessment:
   - Reflect on your achievements from the past year
   - Identify areas for improvement
   - Set goals for the upcoming year
   - Submit through the HR portal

2. Gather Supporting Documents:
   - Project completion certificates
   - Client feedback and testimonials
   - Training completion records
   - Any additional accomplishments

3. Schedule Review Meeting:
   - Coordinate with your manager for a 60-minute review session
   - Prepare to discuss career aspirations and development needs

Review Criteria:
- Goal Achievement (40%)
- Quality of Work (25%)
- Team Collaboration (20%)
- Innovation and Initiative (15%)

This is an excellent opportunity to showcase your contributions and plan your career growth. We encourage you to approach this process with enthusiasm and honesty.

If you have any questions about the review process, please don't hesitate to reach out.

Best regards,
Performance Management Team''',
      'isRead': true, // READ
      'priority': 'medium',
    },
    {
      'id': '4',
      'subject': 'Health & Safety Guidelines Update',
      'sender': 'Safety Committee',
      'senderEmail': 'safety@ecashbook.com',
      'date': 'Aug 15, 2025',
      'time': '09:20 AM',
      'content': '''Dear All,

Your safety and well-being are our top priorities. We are updating our Health & Safety guidelines to ensure a secure work environment for everyone.

Updated Guidelines:

Office Safety:
- Fire evacuation routes updated (see attached map)
- First aid kits locations marked on each floor
- Emergency contact numbers displayed prominently
- Regular safety drills scheduled monthly

Health Protocols:
- Hand sanitizing stations available at all entry points
- Air quality monitoring systems installed
- Regular cleaning and disinfection schedules
- Health screening protocols for visitors

Workspace Ergonomics:
- Adjustable chairs and desks available upon request
- Proper lighting standards maintained
- Eye care guidelines for computer users
- Regular breaks recommended every 2 hours

Incident Reporting:
- Immediate reporting required for any accidents
- Online incident reporting system available
- Investigation procedures for safety concerns
- Follow-up protocols for affected employees

Mental Health Support:
- Employee assistance program available 24/7
- Counseling services provided by qualified professionals
- Stress management workshops scheduled quarterly
- Open-door policy with HR for any concerns

Please familiarize yourself with these updated guidelines. Safety training sessions will be conducted next week - attendance is mandatory.

Stay safe,
Safety Committee
EcashBook Solutions''',
      'isRead': false, // UNREAD
      'priority': 'high',
    },
    {
      'id': '5',
      'subject': 'Team Building Event - Save the Date',
      'sender': 'Events Team',
      'senderEmail': 'events@ecashbook.com',
      'date': 'Aug 12, 2025',
      'time': '04:30 PM',
      'content': '''Hello Everyone!

We're excited to announce our upcoming Team Building Event - a day full of fun, collaboration, and team bonding!

Event Details:
Date: September 15, 2025 (Saturday)
Time: 9:00 AM - 6:00 PM
Venue: Green Valley Resort & Adventure Park
Theme: "Together We Achieve More"

Activities Planned:
- Welcome breakfast and team introductions
- Outdoor adventure challenges
- Problem-solving team exercises
- Sports competitions (cricket, volleyball, badminton)
- Group lunch and networking session
- Awards and recognition ceremony
- Evening cultural program and dinner

What to Bring:
- Comfortable outdoor clothing and shoes
- Sunscreen and personal essentials
- Enthusiasm and team spirit!
- Camera for memorable moments

Transportation:
- Complimentary bus service from office premises
- Departure: 8:00 AM sharp
- Return: Expected by 7:00 PM

RSVP Required:
Please confirm your attendance by August 25, 2025, through the events portal or email events@ecashbook.com.

Special Notes:
- Family members are welcome (additional charges apply)
- Vegetarian and non-vegetarian meal options available
- All safety protocols will be followed
- Weather contingency plans in place

This is a fantastic opportunity to strengthen our bonds, celebrate our successes, and create lasting memories together.

Looking forward to seeing everyone there!

Events Team
EcashBook Solutions''',
      'isRead': true, // READ
      'priority': 'low',
    },
  ];

  // MARK LETTER AS READ WHEN OPENED
  void _markAsRead(String letterId) {
    setState(() {
      final letterIndex = hrLetters.indexWhere((letter) => letter['id'] == letterId); // FIXED: Updated reference
      if (letterIndex != -1) {
        hrLetters[letterIndex]['isRead'] = true; // FIXED: Updated reference
      }
    });
  }

  // GET UNREAD COUNT
  int get _unreadCount => hrLetters.where((letter) => !letter['isRead']).length; // FIXED: Updated reference

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Stats - NO APP BAR
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryPurple, _primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Messages',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${hrLetters.length} letters received', // FIXED: Updated reference
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // DYNAMIC UNREAD COUNT
                  if (_unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accentGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _accentGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_unreadCount New',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'All Read',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Letters List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: hrLetters.length, // FIXED: Updated reference
                itemBuilder: (context, index) {
                  final letter = hrLetters[index]; // FIXED: Updated reference
                  return _buildLetterCard(context, letter, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterCard(BuildContext context, Map<String, dynamic> letter, int index) {
    final bool isUnread = !letter['isRead'];
    final Color priorityColor = _getPriorityColor(letter['priority']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // DIFFERENT BACKGROUND FOR UNREAD
        color: isUnread ? _primaryPurple.withValues(alpha: 0.02) : _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? _primaryPurple.withValues(alpha: 0.3) : _borderColor,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread
                ? _primaryPurple.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // MARK AS READ WHEN TAPPED
            _markAsRead(letter['id']);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HrLetterViewPage(
                  subject: letter['subject'],
                  sender: letter['sender'],
                  senderEmail: letter['senderEmail'],
                  date: letter['date'],
                  time: letter['time'],
                  content: letter['content'],
                  priority: letter['priority'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority Indicator - MORE PROMINENT FOR UNREAD
                Container(
                  width: isUnread ? 5 : 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 16),

                // Sender Avatar - ENHANCED FOR UNREAD
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUnread
                          ? [_primaryPurple, _primaryDark]
                          : [_textLight, _textLight.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: isUnread
                        ? Border.all(color: _primaryPurple.withValues(alpha: 0.3), width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      letter['sender'].toString().substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Letter Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              letter['sender'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                color: isUnread ? _primaryPurple : _textDark,
                              ),
                            ),
                          ),
                          // READ STATUS INDICATOR
                          if (isUnread)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accentOrange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          else
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: _accentGreen,
                                size: 16,
                              ),
                            ),
                          Text(
                            letter['date'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isUnread ? _primaryPurple : _textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Subject - ENHANCED FOR UNREAD
                      Text(
                        letter['subject'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                          color: isUnread ? _textDark : _textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Content Preview
                      Text(
                        letter['content'].toString().replaceAll('\n', ' '),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _textLight,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Unread Indicator Dot - ENHANCED
                if (isUnread) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accentBlue, _primaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: _accentBlue.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return _errorRed;
      case 'medium':
        return _accentBlue;
      case 'low':
        return _accentGreen;
      default:
        return _textLight;
    }
  }
}
