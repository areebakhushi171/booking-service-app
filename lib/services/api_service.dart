import 'dart:async';
import '../models/service_model.dart';
import '../models/review_model.dart';

/// Abstract repository defining contracts for service catalog retrieval
abstract class IServiceRepository {
  Future<List<ServiceModel>> fetchServices();
  Future<ServiceModel> getServiceById(String id);
}

/// Production REST-style ApiService with simulated network latency,
/// debug network fault injection, and mock json backend.
class ApiService implements IServiceRepository {
  static bool simulateNetworkError = false;
  static int simulatedLatencyMs = 650;

  @override
  Future<List<ServiceModel>> fetchServices() async {
    await Future.delayed(Duration(milliseconds: simulatedLatencyMs));

    if (simulateNetworkError) {
      throw Exception(
        'Network error: Unable to reach BookEase API service. Please check your connection or turn off simulated error.',
      );
    }

    return _rawMockServices;
  }

  @override
  Future<ServiceModel> getServiceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (simulateNetworkError) {
      throw Exception('Network error: Unable to fetch service details.');
    }
    return _rawMockServices.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('Service not found'),
    );
  }

  static final List<ServiceModel> _rawMockServices = [
    const ServiceModel(
      id: 'srv-1',
      name: 'Executive Haircut & Beard Sculpting',
      category: 'salon',
      description:
          'A tailored haircut consultation with hot towel treatment, scalp massage, precision scissor styling, and organic beard oil shaping by master barbers.',
      price: 1800,
      durationMinutes: 45,
      rating: 4.9,
      reviewCount: 142,
      imageUrl:
          'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=800&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=800&q=80',
      ],
      features: [
        'Personalized style consultation',
        'Charcoal hair wash and menthol rinse',
        'Hot steam beard softening & straight-razor finish',
        'Herbal soothing aftershave balm',
      ],
      reviews: [
        ReviewModel(
          id: 'r1',
          authorName: 'Hamza Tariq',
          rating: 5,
          date: '2 days ago',
          comment:
              'Best salon experience in Lahore. Very clean tools, polite stylist, and the hot towel finish was superb.',
        ),
        ReviewModel(
          id: 'r2',
          authorName: 'Zain Ul Abideen',
          rating: 5,
          date: '1 week ago',
          comment: 'Punctual and very skilled with fade cuts. Highly recommended!',
        ),
      ],
      isPopular: true,
      isTopRated: true,
    ),
    const ServiceModel(
      id: 'srv-2',
      name: 'Hydra-Glow Herbal Facial & Skin Polish',
      category: 'salon',
      description:
          'Medical-grade 6-step deep facial extraction, ultrasound serum infusion, cooling tea tree mask, and lymphatic drainage for radiant glowing skin.',
      price: 3500,
      durationMinutes: 60,
      rating: 4.8,
      reviewCount: 98,
      imageUrl:
          'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?auto=format&fit=crop&w=800&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?auto=format&fit=crop&w=800&q=80',
      ],
      features: [
        'Digital skin analysis',
        'Ultrasonic pore deep-cleansing',
        'Hyaluronic acid moisture surge infusion',
        'Cryo cooling globes massage',
      ],
      reviews: [
        ReviewModel(
          id: 'r4',
          authorName: 'Ayesha Siddiqui',
          rating: 5,
          date: 'Yesterday',
          comment:
              'Instant brightness! My skin feels completely hydrated and soft without redness.',
        ),
      ],
      isPopular: true,
    ),
    const ServiceModel(
      id: 'srv-3',
      name: 'Swedish Aromatherapy Full Body Massage',
      category: 'wellness',
      description:
          'Gentle to firm rhythmic gliding strokes with heated organic lavender & eucalyptus essential oils. Relieves chronic muscle tension and anxiety.',
      price: 4500,
      durationMinutes: 75,
      rating: 4.9,
      reviewCount: 184,
      imageUrl:
          'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?auto=format&fit=crop&w=800&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?auto=format&fit=crop&w=800&q=80',
      ],
      features: [
        'Choice of 3 organic aromatherapy oils',
        'Heated herbal pressure compress',
        'Targeted lower back & shoulder tension relief',
        'Complimentary herbal green tea',
      ],
      reviews: [
        ReviewModel(
          id: 'r6',
          authorName: 'Omer Farooq',
          rating: 5,
          date: '3 days ago',
          comment:
              'Pure bliss after a stressful week of software deadlines. The therapist was exceptionally skilled.',
        ),
      ],
      isPopular: true,
      isTopRated: true,
    ),
    const ServiceModel(
      id: 'srv-4',
      name: 'Deep Tissue Sport Recovery Therapy',
      category: 'wellness',
      description:
          'High-intensity myofascial release targeting deep muscular knots, trigger points, and athletic fatigue with percussion therapy and arnica balm.',
      price: 5200,
      durationMinutes: 90,
      rating: 4.8,
      reviewCount: 76,
      imageUrl:
          'https://images.unsplash.com/photo-1519823551278-64ac92734fb1?auto=format&fit=crop&w=800&q=80',
      galleryImages: [],
      features: [
        'Postural and trigger-point assessment',
        'Deep thumb and forearm compression',
        'Hypervolt vibration device integration',
        'Post-session assisted stretching',
      ],
      reviews: [
        ReviewModel(
          id: 'r8',
          authorName: 'Saad Malik',
          rating: 5,
          date: '5 days ago',
          comment: 'Recovered quickly from leg day soreness. Very therapeutic pressure.',
        ),
      ],
    ),
    const ServiceModel(
      id: 'srv-5',
      name: 'Complete Home AC Master Service & Chemical Wash',
      category: 'home',
      description:
          'Comprehensive split/inverter air conditioner servicing including indoor unit chemical coil wash, outdoor compressor pressure cleaning, filter sanitization, and gas check.',
      price: 2200,
      durationMinutes: 60,
      rating: 4.7,
      reviewCount: 230,
      imageUrl:
          'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=800&q=80',
      galleryImages: [],
      features: [
        'Eco-friendly antibacterial chemical coil treatment',
        'Blower fan jet cleaning with splash cover',
        'Outdoor condenser fins wash & airflow check',
        'Refrigerant gas pressure digital measurement',
      ],
      reviews: [
        ReviewModel(
          id: 'r10',
          authorName: 'Asad Iqbal',
          rating: 5,
          date: 'Yesterday',
          comment:
              'Cooling improved dramatically! Technician brought proper drop cloths and left no mess on my wall.',
        ),
      ],
      isPopular: true,
    ),
    const ServiceModel(
      id: 'srv-6',
      name: 'Whole Home Deep Sanitization & Carpet Washing',
      category: 'home',
      description:
          'Industrial steam cleaning and antimicrobial sanitization for living rooms, bedrooms, upholstered sofas, and carpets using hospital-grade disinfectants.',
      price: 6500,
      durationMinutes: 120,
      rating: 4.9,
      reviewCount: 115,
      imageUrl:
          'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=800&q=80',
      galleryImages: [],
      features: [
        'Hot water extraction carpet & sofa shampooing',
        'Floor scrubbing with rotary machine',
        'Kitchen degreasing & chimney sanitization',
        'Bathroom limescale removal & grout brightening',
      ],
      reviews: [
        ReviewModel(
          id: 'r12',
          authorName: 'Usman Ali',
          rating: 5,
          date: '1 week ago',
          comment:
              'House smells brand new. The sofa stains from kids are completely gone.',
        ),
      ],
      isTopRated: true,
    ),
    const ServiceModel(
      id: 'srv-7',
      name: 'O/A-Levels Mathematics & Physics 1-on-1 Coaching',
      category: 'tutoring',
      description:
          'Expert certified tutor specializing in Cambridge O/A-Levels syllabus, past-paper walkthroughs, concept clarity, and exam time management.',
      price: 2500,
      durationMinutes: 60,
      rating: 5.0,
      reviewCount: 64,
      imageUrl:
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=800&q=80',
      galleryImages: [],
      features: [
        'Customized diagnostic topic assessment',
        'Topical past papers (2015-2024)',
        'Digital whiteboard recordings provided',
        'Weekly progress report for parents',
      ],
      reviews: [
        ReviewModel(
          id: 'r14',
          authorName: 'Rehan Sheikh',
          rating: 5,
          date: '3 days ago',
          comment:
              'My son jumped from C to A in Calculus within two months. Clear explanations.',
        ),
      ],
      isTopRated: true,
    ),
    const ServiceModel(
      id: 'srv-8',
      name: 'Python & Web Development Bootcamp Mentorship',
      category: 'tutoring',
      description:
          'Practical coding session covering Python, modern JavaScript, API integration, and portfolio project debugging for students and career switchers.',
      price: 3000,
      durationMinutes: 75,
      rating: 4.8,
      reviewCount: 42,
      imageUrl:
          'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=800&q=80',
      galleryImages: [],
      features: [
        'Hands-on pair programming session',
        'Code review and clean architecture tips',
        'GitHub repository setup & project guidance',
        'Interview question preparation',
      ],
      reviews: [
        ReviewModel(
          id: 'r16',
          authorName: 'Daniyal Ahmed',
          rating: 5,
          date: '4 days ago',
          comment:
              'Debugged my full-stack API in 20 minutes and taught me how to write unit tests.',
        ),
      ],
    ),
    const ServiceModel(
      id: 'srv-9',
      name: 'Licensed In-Home Nursing & Vital Monitoring',
      category: 'health',
      description:
          'Certified registered nurse home visit for elderly care, post-surgical wound dressing, IV cannulation, blood glucose checks, and medication administration.',
      price: 3200,
      durationMinutes: 60,
      rating: 4.9,
      reviewCount: 153,
      imageUrl:
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
      galleryImages: [],
      features: [
        'Complete vitals charting (BP, SpO2, Heart Rate, Sugar)',
        'Aseptic wound dressing change',
        'Medication administration & doctor notes sync',
        'Compassionate elderly care support',
      ],
      reviews: [
        ReviewModel(
          id: 'r18',
          authorName: 'Dr. Imtiaz Hassan',
          rating: 5,
          date: 'Yesterday',
          comment:
              'Booked for my mother recovering from hip surgery. Nurse was incredibly caring and meticulous.',
        ),
      ],
      isPopular: true,
      isTopRated: true,
    ),
    const ServiceModel(
      id: 'srv-10',
      name: 'At-Home Physiotherapy & Mobility Rehabilitation',
      category: 'health',
      description:
          'Personalized physical rehabilitation for stroke recovery, joint arthritis, frozen shoulder, and sports injuries by licensed DPT doctors.',
      price: 3800,
      durationMinutes: 60,
      rating: 4.8,
      reviewCount: 88,
      imageUrl:
          'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=800&q=80',
      galleryImages: [],
      features: [
        'Comprehensive range-of-motion testing',
        'TENS machine electrotherapy',
        'Therapeutic exercise prescription',
        'Ergonomic home adjustment advice',
      ],
      reviews: [
        ReviewModel(
          id: 'r20',
          authorName: 'Kamran Akram',
          rating: 5,
          date: '3 days ago',
          comment:
              'Frozen shoulder mobility is back to 85% after 4 sessions. Very knowledgeable doctor.',
        ),
      ],
    ),
    const ServiceModel(
      id: 'srv-11',
      name: 'Premium Car Detailing & Interior Shampooing',
      category: 'auto',
      description:
          'At-your-doorstep complete automotive detail: high-pressure foam wash, wheel de-ironizing, leather seat deep cleaning, steam vent sterilization, and wax protection.',
      price: 4800,
      durationMinutes: 90,
      rating: 4.9,
      reviewCount: 210,
      imageUrl:
          'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?auto=format&fit=crop&w=800&q=80',
      galleryImages: [],
      features: [
        'pH-neutral snow foam wash with 2-bucket method',
        'Interior leather conditioning & upholstery steam extraction',
        'AC duct ozone odor removal treatment',
        'Synthetic sealant wax coating for 3-month gloss',
      ],
      reviews: [
        ReviewModel(
          id: 'r22',
          authorName: 'Shahzaib Lodhi',
          rating: 5,
          date: '2 days ago',
          comment:
              'Car looks showroom fresh! Coffee stains on the driver seat were completely removed.',
        ),
      ],
      isPopular: true,
      isTopRated: true,
    ),
    const ServiceModel(
      id: 'srv-12',
      name: 'Full Vehicle Diagnostic Scan & Engine Tune-Up',
      category: 'auto',
      description:
          'Mobile mechanic inspection including OBD2 electronic sensor scanning, spark plug replacement, brake pad wear check, fluid top-ups, and battery load testing.',
      price: 3600,
      durationMinutes: 60,
      rating: 4.7,
      reviewCount: 95,
      imageUrl:
          'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=800&q=80',
      galleryImages: [],
      features: [
        'Complete OBD2 scan with fault code diagnostic report',
        'Brake pads, rotors & fluid check',
        'Battery alternator health test',
        'Coolant and steering fluid level inspection',
      ],
      reviews: [
        ReviewModel(
          id: 'r24',
          authorName: 'Taimoor Rasheed',
          rating: 5,
          date: '4 days ago',
          comment:
              'Identified the oxygen sensor issue that two local workshops missed. Saved me 30k.',
        ),
      ],
    ),
  ];
}
