import sys
import os
try:
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.units import inch, mm
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Frame, PageTemplate, Image
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.enums import TA_JUSTIFY, TA_CENTER, TA_LEFT
except ImportError:
    print("Reportlab not installed")
    sys.exit(1)

def build_pdf():
    file_path = "C:/MAD/Therap_app/RespiriCare_Conclave_Paper_Final.pdf"
    
    page_width, page_height = A4
    
    left_margin = 15 * mm
    right_margin = 15 * mm
    top_margin = 20 * mm
    bottom_margin = 25 * mm
    
    doc = SimpleDocTemplate(
        file_path, 
        pagesize=A4,
        rightMargin=right_margin,
        leftMargin=left_margin,
        topMargin=top_margin,
        bottomMargin=bottom_margin
    )

    styles = getSampleStyleSheet()
    
    title_style = ParagraphStyle(
        'TitleStyle',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=18,
        leading=22,
        alignment=TA_CENTER,
        spaceAfter=25
    )

    author_style = ParagraphStyle(
        'AuthorStyle',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=11,
        alignment=TA_CENTER,
        leading=14,
        spaceAfter=30
    )

    abstract_text_style = ParagraphStyle(
        'AbstractText',
        parent=styles['Normal'],
        fontName='Times-BoldItalic',
        fontSize=9.5,
        leading=12,
        alignment=TA_JUSTIFY,
        spaceAfter=15
    )

    body_style = ParagraphStyle(
        'BodyText',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=10,
        leading=13,
        alignment=TA_JUSTIFY,
        firstLineIndent=4*mm,
        spaceAfter=6
    )

    heading_1_style = ParagraphStyle(
        'Heading1',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=10,
        alignment=TA_CENTER,
        textTransform='uppercase',
        spaceBefore=18,
        spaceAfter=12
    )

    heading_2_style = ParagraphStyle(
        'Heading2',
        parent=styles['Normal'],
        fontName='Times-Italic',
        fontSize=10,
        spaceBefore=12,
        spaceAfter=6,
        alignment=TA_LEFT
    )
    
    heading_bold_style = ParagraphStyle(
        'HeadingBold',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=10,
        textTransform='uppercase',
        spaceBefore=12,
        spaceAfter=6,
        alignment=TA_LEFT
    )

    bullet_style = ParagraphStyle(
        'BulletStyle',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=10,
        leading=13,
        alignment=TA_JUSTIFY,
        leftIndent=8*mm,
        firstLineIndent=-4*mm,
        spaceAfter=6
    )

    story = []

    # Title & Authors
    story.append(Paragraph("RespiriCare: A Comprehensive Mobile Ecosystem for Multi-Role Clinical Triage and Remote Care", title_style))
    
    author_text = """
    Archana Sasi &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Dr. V. Umarani<br/>
    Master of Computer Applications &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Assistant Professor (Sl. Gr.)<br/>
    Dept. of Computer Applications &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Dept. of Computer Applications<br/>
    PSG College of Technology &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; PSG College of Technology<br/>
    Coimbatore, India  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Coimbatore, India<br/>
    23mx118@psgtech.ac.in &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; vur.mca@psgtech.ac.in<br/>
    """
    story.append(Paragraph(author_text, author_style))

    # Abstract
    story.append(Paragraph("Abstract - Traditional outpatient healthcare delivery systems often suffer from fragmented communication and siloed monitoring. RespiriCare is a comprehensive mobile application that attempts to solve this problem by offering an integrated digital ecosystem tailored for distinct clinical roles. The platform connects patients, diagnosing physicians, and dispensing pharmacists through real-time data synchronization. RespiriCare employs a robust electronic prescription module, remote teleconsultation capabilities, and an automated alerting engine designed to track patient medication adherence. In this work, the software's architecture, role-based subsystem evaluation, and its effectiveness in mitigating treatment failure through proactive pharmacy notification are considered and proved how it enhances healthcare outcomes.", abstract_text_style))

    story.append(Paragraph("RespiriCare is a clinical application that utilizes the application of automated tracking logic to give its users an interactive healthcare experience that is real and tailored to each patient. This is different from the conventional method. This application designs digital prescriptions based on what the doctor dictates, clinical clinical vitals, and their diagnosis level. Patients can respond in the form of daily symptom logs and medication status updates. The system takes these inputs into consideration in terms of what they actually log, how well they adhere to regimens, and their recovery status. The system then goes ahead to give alerts to pharmacists that they can use to intervene. The system provides a detailed chronological layout through which the doctors know their patients' progression and areas of physiological improvements.", body_style))
    story.append(Paragraph("The increasing realization of the necessity of real-time assessment tools for remote care calls for a systematic, scalable, and smart clinic preparation solution. RespiriCare fills this gap by being founded on cloud-synchronized architectures and real-time teleconsultation processing, closing the gap between theoretical care plans and actual patient recuperation situations. Currently, hospitals are increasingly employing remote recruitment tools, and clinics also need equally sophisticated platforms to execute these consultations. This study analyses RespiriCare's architecture, the effect it generates on adherence preparedness, and the comparative benefits it provides over conventional tracking techniques, setting its potential to revolutionize outpatient care.", body_style))

    # I. INTRODUCTION
    story.append(Paragraph("I. INTRODUCTION", heading_1_style))
    story.append(Paragraph("Patient care preparation has always been crucial but difficult for clinics. It relies on solitary tracking with standard lists of physical symptoms, or finding a doctor face-to-face. But such practices don't offer personalized guidance, timely feedback, or fair mechanisms to assess how well one is doing. These factors make it challenging for patients to master their adherence. As digital technologies continue to evolve, technical solutions are transforming the process of healthcare management. These new solutions provide data driven feedback and structured ways to measure capabilities.", body_style))
    
    # II. SCOPE OF THE APPLICATION
    story.append(Paragraph("II. SCOPE OF THE APPLICATION", heading_1_style))
    story.append(Paragraph("The scope of the application is to deliver a robust role-based healthcare platform that improvises patients' access to care, physician confidence, and overall clinical performance through structured digital ecosystems. Role-based workflows are developed by RespiriCare and prescription verifications, teleconsultation streams, and medication adherence are analysed based on automated rule analytics.", body_style))
    story.append(Paragraph("The platform features user registration, personalized prescription tracking, live video consultations, and comprehensive performance reports with actionable insights. Doctors get comparative analysis and progress tracking, allowing for ongoing refinement. The platform supports both new patients and seasoned clinicians, filling the gap between old preparation techniques and modern healthcare expectations, providing a scalable, data-driven, and accessible management solution.", body_style))

    # III. TECHNOLOGY OVERVIEW
    story.append(Paragraph("III. TECHNOLOGY OVERVIEW", heading_1_style))
    story.append(Paragraph("This section outlines the tools and technologies used in the development of RespiriCare. The application is integrated with real-time video processing and cloud-based architectures to deliver a seamless and intelligent healthcare management experience.", body_style))
    
    story.append(Paragraph("FLUTTER", heading_bold_style))
    story.append(Paragraph("Flutter, as defined by Google, is an open-source UI software development kit. Runtime flexibility and declarative programming features make this framework stand out from the pack. It supports multiple application targets, including event-driven iOS and Android outputs. A variety of application programming interfaces (APIs) allow it to interact with capabilities for handling native device hardware, camera access, and fluid material design layouts.", body_style))
    story.append(Paragraph("Flutter engines were first designed for mobile ecosystems but have since become foundational for cross-platform deployments. For this purpose, Dart is the primary programming language. Each major compilation target includes a dedicated engine to execute Dart code.", body_style))
    
    story.append(Paragraph("DART", heading_bold_style))
    story.append(Paragraph("Dart, a client-optimized language, enables developers to craft UI by combining modular and reusable widget trees. The platform is backed by Google along with a global community of independent developers and organizations. By leveraging tools like standard Flutter SDKs, Dart can be adapted to build complex SPAs and mobile apps. Dart manages application state and updates the UI accordingly, which means creating applications using Dart typically relies on external state frameworks for handling routing, as well. Provider serves as a Dart-based state library with components designed for building clean and predictable flows.", body_style))

    story.append(Paragraph("FIREBASE", heading_bold_style))
    story.append(Paragraph("Firebase serves as a backend-as-a-service platform powered by Google and available to ensure scalability and performance for Flutter apps. It offers real-time NoSQL database synchronization for quick load times and improved messaging. With additional benefits of native authentication APIs, cloud storage, along with serverless cloud functions, Firebase is an excellent developer experience and is now ideal for scalable high-performance cross-platform applications.", body_style))

    story.append(Paragraph("WEBRTC", heading_bold_style))
    story.append(Paragraph("WebRTC is a widely used open-source communications project known for its adherence to peer-to-peer standards, stability, and low latency. WebRTC organizes media in a structured way as audio, video, and data channels, and provides data integrity based on firm adherence to encryption properties. WebRTC can support advanced streaming methods and high concurrency and is hence also appropriate for small-scale medical teleconsultations.", body_style))

    story.append(Spacer(1, 10))
    story.append(Paragraph("IV. SYSTEM ANALYSIS", heading_1_style))
    story.append(Paragraph("This section comprises a comparative evaluation of the existing systems and the system proposed here, focusing on its efficiency, effectiveness, and benefits, is described. By identifying the shortcomings in the existing system and resolving them through innovative technology methods, system analysis provides an organized and effective way of designing applications.", body_style))
    
    story.append(Paragraph("A. Existing system", heading_2_style))
    story.append(Paragraph("Existing healthcare tracking platforms are comprehensively utilized to prepare digital logs, and they have their core use in isolated tracking assessments. These platforms review inputs in order to check medication intake and adherence pertinence. Although they generate valuable feedback concerning dosage abilities, they fail to offer comprehensive appraisal metrics such as live communication with doctors, closed-loop prescription passing, and clinical behavioral patterns that contribute a large percentage to curing a patient based on holistic physiological state. The lack of organized unified tools restricts their contribution to providing a pragmatic clinical simulation, with a gap remaining for general preparation of the patients for complete recovery.", body_style))

    story.append(Paragraph("B. Proposed System", heading_2_style))
    story.append(Paragraph("The proposed RespiriCare platform delivers an end-to-end digital verification network by analyzing both patient inputs and pharmaceutical checkpoints. In contrast to traditional systems that mainly analyze isolated metrics, RespiriCare combines real-time teleconsultation, secure prescription routing, and intelligent miss-medication analysis to give a complete performance assessment. This advanced system allows doctors to receive real-time feedback on their patients' adherence and areas of regression, making them more efficient and engaging clinical interventions. By closing the gap between patient tracking and medical intervention behavior, RespiriCare prepares hospitals better for actual remote professional interactions in outpatient scenarios.", body_style))

    # V. SYSTEM DESIGN
    story.append(Paragraph("V. SYSTEM DESIGN", heading_1_style))
    story.append(Paragraph("System design is an iterative methodology that converts requirements into a blueprint or a representation of software that can be accessed for quality before code generation starts. It establishes the architecture, parts, and relationships necessary for building a scalable and effective system. This stage ensures feasibility check, performance optimization, and early defect fixing, resulting in an efficient and streamlined software solution.", body_style))
    
    story.append(Paragraph("A. SYSTEM FLOW DIAGRAM", heading_2_style))
    story.append(Paragraph("Figure 5.1 describes how the software communicates within itself and with the systems that interoperate with it.", body_style))
    
    if os.path.exists("C:/MAD/Therap_app/use_case_diagram.png"):
        try:
            img = Image("C:/MAD/Therap_app/use_case_diagram.png", width=3*inch, height=2.2*inch)
            story.append(img)
        except Exception:
            story.append(Spacer(1, 2.2*inch))
    else:
        story.append(Spacer(1, 2.2*inch))
        
    story.append(Paragraph("Figure 5.1 System Flow Diagram", ParagraphStyle('Caption', parent=styles['Normal'], alignment=TA_CENTER, fontName='Times-Roman')))
    story.append(Spacer(1, 15))
    
    story.append(Paragraph("The RespiriCare platform plans to provide an integrated tri-role experience through the evaluation of both patient logs and clinical metrics. Figure 5.1 is the system flow diagram illustrating the formalized flow that ensures seamless interaction among users and the automated assessment modules.", body_style))
    story.append(Paragraph("The process starts with the user authentication process, where actors register or log in to access the platform. Successful authentication is followed by the role initialization phase, where users are routed to specialized dashboards depending on their profiles. The system proceeds to the active engagement phase, where patients log vitals. The doctor module captures these responses, and the pharmacist module assesses secondary responses such as prescription fulfillment and missed occurrences.", body_style))

    # VI. MODULES
    story.append(Paragraph("VI. MODULES", heading_1_style))
    story.append(Paragraph("This section presents the core components of the system, each designed to contribute to its overall functionality and effectiveness. These modules work together to ensure a seamless, efficient, and comprehensive user experience.", body_style))

    story.append(Paragraph("A. Registration and Login", heading_2_style))
    story.append(Paragraph("The user starts by registering for the RespiriCare platform to provide basic information. This is for verification purposes; once registered, the user can log into their account with the above information to access the platform. The platform provides the users with the ability to control their profiles and change relevant details whenever they would like.", body_style))

    story.append(Paragraph("B. Digital Prescription Generation", heading_2_style))
    story.append(Paragraph("The generation module provides dynamically updating clinical records depending on the physician's diagnosis. The system uses structured input methods to generate pertinent prescriptions to ensure the medical process is unique and complete. This module aims to integrate real-world hospital situations by modifying the dosage requirements and structure, based on what the patient conveys in consultation.", body_style))

    story.append(Paragraph("C. Medication Tracking Alerts", heading_2_style))
    story.append(Paragraph("The adherence tracking module translates prescriptions into schedule-based reminders. The adherence logic triggers automated tracking loops. If a medication is marked as missed, the platform automatically flags it for pharmacy evaluation, permitting assessment of treatment clarity, fluency, and execution with further analysis.", body_style))
    
    story.append(Paragraph("D. Teleconsultation Analysis", heading_2_style))
    story.append(Paragraph("The teleconsultation module focuses on evaluating real-time communication between doctor and patient. The system employs WebRTC peer-to-peer techniques to analyze the patient visually and aurally. This component is pertinent to the overall evaluation of the patient's performance by reviewing relevant physiological cues that are important for effective diagnosis.", body_style))

    # VII. COMPARATIVE ANALYSIS
    story.append(Paragraph("VII. COMPARATIVE ANALYSIS", heading_1_style))
    story.append(Paragraph("This section explores how clinical tracking has evolved over time, comparing traditional methods with digital tri-role platforms. It provides insights into their strengths, limitations, and overall impact on a patient's readiness for real-world recovery.", body_style))
    story.append(Paragraph("The remote care approach has experienced remarkable transformation over the past decade owing to advancements in mobile frameworks and cloud technology. Traditionally, clinics used solo study, standard clinical records, or physical tracking with mentors. Although these practices have worked to an extent, they do not yield personalized tracking, formal evaluation, and immediate safety nets for missed medication communication.", body_style))
    
    story.append(Paragraph("A. Feedback Quality and Personalization", heading_2_style))
    story.append(Paragraph("Conventional approaches to managing outpatient care often do not have the speed of feedback needed for doctors to gain a true understanding of a patent's progression. Practicing checkups via scheduled physical visits tends to yield qualitative feedback that is delayed and does not address specific daily metrics for improvement. In contrast, integrated platforms like RespiriCare offer immediate, data-driven insightful takeaways considering both patient self-reporting and background adherence behavior.", body_style))
    
    story.append(Paragraph("• Real-Time Analysis: RespiriCare uses constant automated service state processing to analyze patients' adherence during home recuperation. This allows for immediate feedback on aspects such as chronicity of symptoms and overall medication coherence.", bullet_style))
    story.append(Paragraph("• Personalized Insights: Instead of generic follow-up calls, the platform generates dynamic alerting based on the severity of the illness and the specific thresholds of the prescription, resulting in a targeted and relevant medical safety net.", bullet_style))

    story.append(Paragraph("B. Accessibility and Cost Efficiency", heading_2_style))
    story.append(Paragraph("Accessibility is still a big issue in the conventional clinical management processes. Constant physical checkups can be costly and depends on geographical location or scheduling options that most patients lack.", body_style))
    
    story.append(Paragraph("• Democratization of Resources: Cloud-driven platforms like RespiriCare offer 24/7 access to clinical prescriptions, automated reminders, and direct emergency access to remote pharmacists regardless of location at a fraction of the cost. This democratizes quality healthcare orchestration for patients of different backgrounds.", bullet_style))
    story.append(Paragraph("• Scalability: Human care coordinators are limited to handling a certain number of patients at a time, whereas cloud-based tools can handle thousands of them without sacrificing the quality of feedback. The cost-effectiveness of these platforms minimizes tracking costs by as much as 80%, making them viable for more people.", bullet_style))

    # Incorporating the final sections from the newest image (Image 6)
    story.append(Paragraph("C. Skill Development and Performance Outcomes", heading_2_style))
    story.append(Paragraph("The success of any preparation method really lies in the ability to develop the skills needed for successful completion of treatment plans.", body_style))
    
    story.append(Paragraph("• Comprehensive Skill Assessment: RespiriCare evaluates adherence (e.g., medication timing) and physiological cues (e.g., symptom severity, vitals) seamlessly. This two-way evaluation enables doctors to polish their overall medical presentation.", bullet_style))
    story.append(Paragraph("• Adaptive Care Environment: Real-time platforms adapt dosage difficulty according to patient performance, mimicking real-life care interventions that doctors will execute during actual clinical rounds.", bullet_style))

    story.append(Paragraph("D. Ethical Considerations and Limitations", heading_2_style))
    story.append(Paragraph("As future AI-enabled tracking tools become more developed and disseminated, it is worth discussing the ethical realities and potential limitations of using this type of technology. Digital tri-role tools have many benefits, but there are important limitations to mitigate without compromising fairness, transparency, or authenticity.", body_style))
    
    story.append(Paragraph("• Authenticity vs. Over-Reliance: Pharmacists may become so reliant on automated alerting that routine verification procedures might be overlooked, turning into a robotic response mechanism in the actual hospital.", bullet_style))
    story.append(Paragraph("• Data Privacy Concerns: The gathering of biometric data (symptoms, facial teleconsultations, and location) will necessitate rigorous data protection practices (such as HIPAA compliance) to ensure patient privacy concerns are met.", bullet_style))
    story.append(Paragraph("• Algorithmic Bias: Regular monitoring and auditing of tracking data are necessary to mitigate the perpetuation of biased healthcare practices based on existing historical trends.", bullet_style))

    story.append(Paragraph("VIII. CONCLUSION", heading_1_style))
    story.append(Paragraph("RespiriCare fills the gap between conventional paper-based tracking and modern digital solutions by providing instant feedback on adherence, physiological symptoms, and overall recovery performance. In contrast to traditional approaches based on generic lists of check-ins or siloed portals with care staff, RespiriCare provides a tailored and interactive experience. This enables clinics to practice in an environment that closely mirrors in-person treatment, allowing them to gain confidence and enhance their clinical outcomes.", body_style))
    
    story.append(Paragraph("With remote management tools increasingly prevalent, patients need an equally smart and dynamic tracking platform. RespiriCare overcomes major issues such as data fragmentation, missing prescription loops, and excessive dependence on patient memory through transparency and continuous data application. In the future, the platform can improve further, for instance, by introducing disease-specific automated triage situations and enhancing its ML-driven care advising features. With ongoing innovations, RespiriCare hopes to make clinical triage smarter, more equitable, and accessible to all.", body_style))

    story.append(Paragraph("Future developments for RespiriCare will focus on improvising personalization and accessibility. Multilingual support could help non-native speaking patients to practice in their native language without feeling anxious. Furthermore, providing automated hardware sensors with varying levels of granularity could result in a more organized analytics path. Advancing the quality of teleconsultation by assessing confidence in facial expressions and vocal tones, as well as identifying emotion, could improve the overall telehealth experience. Lastly, providing live AI coaching or an AI-powered symptom mentor could offer immediate guidance, increasing tracking effectiveness and patient engagement.", body_style))


    col_width = (page_width - left_margin - right_margin - 8*mm) / 2.0
    
    frame1 = Frame(left_margin, bottom_margin, col_width, page_height - top_margin - bottom_margin, id='col1', leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
    frame2 = Frame(left_margin + col_width + 8*mm, bottom_margin, col_width, page_height - top_margin - bottom_margin, id='col2', leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
    
    doc.addPageTemplates([PageTemplate(id='TwoCol', frames=[frame1, frame2])])
    doc.build(story)

if __name__ == '__main__':
    build_pdf()
