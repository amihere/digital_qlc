# Eli Mental Health Support Bot Configuration

This file defines the questions and flow for Eli, a mental health support chatbot for mothers.

## start

**Question:** Hey there! I'm Eli. You can think of me as a friend. I'm designed to help women on their parenting journeys who may be experiencing mental distress. I can help with simple exercises specifically relevant to your challenges. And if you prefer, I can connect you with other mothers who can relate with your experiences or some professionals later. I'm really glad you reached out. What should I call you?
**Type:** text
**Next:** privacy_intro

---

## privacy_intro

**Question:** Nice to meet you, {name}. I'm here to listen and support you. Before we start, I need to ask for a couple of details to personalize your experience. Your privacy is my highest priority. I will only ask for information when it's needed to help you, and you can always choose to skip a question. Everything you share is kept private and secure. You can read our full Privacy Policy here (https://qlc-sister-circle.onrender.com/public/privacypol) at any time. How old are you? [For example: 32]
**Type:** text
**Next:** location

---

## location

**Question:** Where do you live? [For example: Accra, Ghana]
**Type:** text
**Next:** country

---

## country

**Question:** What country are you from?
**Type:** choice
**Options:** Ghana, Nigeria, South Africa, Kenya, Jamaica, USA, Other (please type)
**Next:** case country: Ghana -> mental_health_experience, Nigeria -> mental_health_experience, South Africa -> mental_health_experience, Kenya -> mental_health_experience, Jamaica -> mental_health_experience, USA -> mental_health_experience, Other (please type) -> country_other

---

## country_other

**Question:** Please tell us which country you are from:
**Type:** text
**Next:** mental_health_experience

---

## mental_health_experience

**Question:** Perfect. And have you ever talked to a mental health professional before, or used an app like this?
**Type:** choice
**Options:** Yes both, Yes only a professional, Yes only an app, No this is my first time
**Next:** parenthood_stage

---

## parenthood_stage

**Question:** Thanks so much for your patience, {name}. Now let's talk about why you're here. What stage of parenthood are you?
**Type:** choice
**Options:** I'm trying to conceive, I'm still pregnant, I've lost a pregnancy / baby, I'm a nursing mother
**Next:** case parenthood_stage: I'm trying to conceive -> pathway_coming_soon, I'm still pregnant -> pathway_coming_soon, I've lost a pregnancy / baby -> pl_opening, I'm a nursing mother -> nursing_mother_concerns

---

## pathway_coming_soon

**Question:** Thank you for sharing that with me, {name}. Support built specifically for your stage of the journey is coming very soon - and what you're carrying matters just as much today. Our care team is still here for you right now. Would you like to look at some support options?
**Type:** choice
**Options:** Show me support options, I'll come back later
**Next:** case pathway_coming_soon: Show me support options -> checkout_point, I'll come back later -> end_gracefully

---

## nursing_mother_concerns

**Question:** {name}, i want you to know that the journey of a nursing mother is its own unique world, with its own joys and its own heavy days. I'm here for all of it. What exactly is your concern today?
**Type:** choice
**Options:** I feel sad or disconnected from my baby, My baby's in the NICU, I'm stressed and anxious, I want to check my blood pressure / I have a physical concern
**Next:** case nursing_mother_concerns: I feel sad or disconnected from my baby -> sad_disconnected_intro, My baby's in the NICU -> nicu_concern, I'm stressed and anxious -> stress_anxiety_intro, I want to check my blood pressure / I have a physical concern -> bp_intro

---

## sad_disconnected_intro

**Question:** That can be such a lonely feeling—especially when everyone expects you to be happy. Thank you for being honest about it. To help me understand what's happening, I'm going to ask you 10 short questions. This is a standard guide called the EPDS, designed to help mothers see how they've been feeling over the past 7 days. Please answer as honestly as you can. There are no right or wrong answers here. Is that okay?
**Type:** choice
**Options:** Yes let's continue, No I need a pause
**Next:** case sad_disconnected_intro: Yes let's continue -> epds_q1, No I need a pause -> pause_options

---

## pause_options

**Question:** Of course. We stop right here. You are in control. Let's just breathe. I'm right here. We can look at some support options now if you'd like, or you can just rest. What feels right?
**Type:** choice
**Options:** Show me support options now, I want to rest. That's all.
**Next:** case pause_options: Show me support options now -> checkout_point, I want to rest. That's all. -> rest_exercise_offer

---

## rest_exercise_offer

**Question:** That is a perfect choice. Listening to what you need is the most important thing. Before you go, would you be open to a very short, quiet exercise? It's not about fixing anything, just about offering yourself a moment of kindness. No pressure at all if you'd rather not.
**Type:** choice
**Options:** Yes I'll try, No thank you
**Next:** case rest_exercise_offer: Yes I'll try -> kindness_exercise, No thank you -> end_gracefully

---

## kindness_exercise

**Question:** Okay, mama. Wherever you are, just get comfortable. If it feels okay, you can place a hand over your heart. Now, just silently repeat this phrase to yourself: "This is a hard moment. All mothers have hard moments. May I be kind to myself right now." That's it. Just a little bit of warmth for yourself. Rest well. I'm here when you're ready.
**Type:** summary
**Next:** nil

---

## end_gracefully

**Question:** Understood. Rest well, mama. I'm here when you're ready.
**Type:** summary
**Next:** nil

---

## epds_q1

**Question:** Remember to answer based on how you have felt during the past 7 days. I have been able to laugh and see the funny side of things.
**Type:** choice
**Options:** As much as I always could, Not quite so much now, Definitely not so much now, Not at all
**Next:** epds_q2

---

## epds_q2

**Question:** I have looked forward with enjoyment to things.
**Type:** choice
**Options:** As much as I ever did, Rather less than I used to, Definitely less than I used to, Hardly at all
**Next:** epds_q3

---

## epds_q3

**Question:** I have blamed myself unnecessarily when things went wrong.
**Type:** choice
**Options:** Yes most of the time, Yes some of the time, Not very often, No never
**Next:** epds_q4

---

## epds_q4

**Question:** I have been anxious or worried for no good reason.
**Type:** choice
**Options:** No not at all, Hardly ever, Yes sometimes, Yes very often
**Next:** epds_q5

---

## epds_q5

**Question:** I have felt scared or panicky for no very good reason.
**Type:** choice
**Options:** Yes quite a lot, Yes sometimes, No not much, No not at all
**Next:** epds_q6

---

## epds_q6

**Question:** Have you felt so overwhelmed that it's been hard to cope?
**Type:** choice
**Options:** Yes most of the time I haven't been able to cope at all, Yes sometimes I haven't been coping as well as usual, No most of the time I have coped quite well, No I have been coping as well as ever
**Next:** epds_q7

---

## epds_q7

**Question:** I have been so unhappy that I have had difficulty sleeping.
**Type:** choice
**Options:** Yes most of the time, Yes sometimes, Not very often, No not at all
**Next:** epds_q8

---

## epds_q8

**Question:** I have felt sad or miserable.
**Type:** choice
**Options:** Yes most of the time, Yes quite often, Not very often, No not at all
**Next:** epds_q9

---

## epds_q9

**Question:** I have been so unhappy that I have been crying.
**Type:** choice
**Options:** Yes most of the time, Yes quite often, Only occasionally, No never
**Next:** epds_q10

---

## epds_q10

**Question:** The thought of harming myself has occurred to me.
**Type:** choice
**Options:** Yes quite often, Sometimes, Hardly ever, Never
**Next:** case epds_q10: Yes quite often -> safety_protocol, Sometimes -> safety_protocol, Hardly ever -> epds_completion, Never -> epds_completion

---

## crisis_checkin

**Question:** {name}, I hear you. Your safety is the only thing that matters right now. Please call this number immediately: 0800678678. They are available 24/7 to talk and can offer immediate confidential support. Can you please confirm you have seen this number?
**Type:** choice
**Options:** Yes I have seen the number
**Next:** safety_confirmation

---

## safety_protocol

**Question:** Thank you for being so honest with me, {name}. That is the most important thing you could have shared. Because you've indicated you're having thoughts of harming yourself, your safety is the only thing that matters right now. I need to stop our chat and connect you with help. Please call this number immediately: 0800678678. They are available 24/7 to talk and can offer immediate, confidential support. Can you please confirm you have seen this number?
**Type:** choice
**Options:** Yes I have seen the number
**Next:** safety_confirmation

---

## safety_confirmation

**Question:** Thank you. Please reach out to them now. Bye
**Type:** summary
**Next:** nil

---

## epds_completion_high

**Question:** Thank you for sharing all of that with me, {name}. You have done a hard thing today by putting words to your experience. Based on everything you've told me, it might be best to speak to a professional. Would you like our team to reach out to you in the next 72 hours to discuss scheduling a call with a professional?
**Type:** choice
**Options:** Yes, No
**Next:** case epds_completion_high: Yes -> feedback_request, No -> final_summary

---

## epds_completion_mid

**Question:** Thank you for sharing all of that with me, {name}. You have done a hard thing today by putting words to your experience. Based on everything you've told me, connecting with more support could be a really kind next step for yourself. What feels like the best option for you right now?
**Type:** choice
**Options:** Explore talking to a professional, Learn about the community support group, Just rest for now. I need time to think.
**Next:** case epds_completion_mid: Explore talking to a professional -> professional_contact, Learn about the community support group -> community_group_info, Just rest for now. I need time to think. -> rest_choice

---

## epds_completion

**Question:** Thank you for sharing all of that with me, {name}. You have done a hard thing today by putting words to your experience. Based on everything you've told me, here are some options for you. What feels like the best for you right now?
**Type:** choice
**Options:** Learn about the community support group, Just rest for now. I need time to think.
**Next:** case epds_completion: Learn about the community support group -> community_group_info, Just rest for now. I need time to think. -> rest_choice

---

## nicu_concern

**Question:** Oh, mama. That is so much to hold. The NICU journey is a path of incredible strength, lived one moment at a time. It's okay to feel suspended between hope and fear. What's been the hardest part for you recently?
**Type:** choice
**Options:** The constant worry about my baby's health, I feel disconnected, Feeling guilty - like it's my fault my baby is here
**Next:** case nicu_concern: The constant worry about my baby's health -> stress_anxiety_intro, I feel disconnected -> sad_disconnected_intro, Feeling guilty - like it's my fault my baby is here -> guilt_response

---

## guilt_response

**Question:** Oh, mama. Please hear me. This is not your fault. You are your baby's safe place, their comfort, and their fiercest advocate. Guilt is a heavy, unfair weight that so many mothers carry, but you do not deserve it. Your love is what matters. This is so much for one person to hold, and you don't have to carry it alone.
**Type:** text
**Next:** checkout_point

---

## stress_anxiety_intro

**Question:** That sounds exhausting—like your body and mind are on high alert with no chance to rest. That is a heavy load to carry. Let's see if we can give your mind a place to land. Would you be willing to try a quick, 30-second grounding exercise with me?
**Type:** choice
**Options:** Yes let's try, Not right now thanks
**Next:** case stress_anxiety_intro: Yes let's try -> grounding_exercise, Not right now thanks -> stress_explanation

---

## grounding_exercise

**Question:** Okay. Let's try the 5-4-3-2-1 Method. Right where you are, just softly name... 5 things you can see, 4 things you can feel, 3 things you can hear, 2 things you can smell, and 1 good thing about yourself. Take a slow breath. You just brought your mind back to the present moment. Thank you for trying that with me. It's a tool you can use anytime the spiral starts.
**Type:** text
**Next:** stress_explanation

---

## stress_explanation

**Question:** That experience you described—the constant tension and the racing thoughts—is a sign that your mind and body are stuck on high alert. That is an exhausting way to live, and it's a very common experience for nursing mothers. Since you don't feel like engaging with any exercises now, would you like to explore any of these other options?
**Type:** choice
**Options:** Explore talking to a professional, Learn about the community support group, Just rest for now. I need time to think.
**Next:** case stress_explanation: Explore talking to a professional -> professional_contact, Learn about the community support group -> community_group_info, Just rest for now. I need time to think. -> rest_choice

---

## checkout_point

**Question:** Thank you for sharing all of that with me, {name}. You have done a hard thing today by putting words to your experience. Based on everything you've told me, connecting with more support could be a really kind next step for yourself. What feels like the best option for you, right now?
**Type:** choice
**Options:** Explore talking to a professional, Learn about the community support group, Just rest for now. I need time to think.
**Next:** case checkout_point: Explore talking to a professional -> professional_contact, Learn about the community support group -> community_group_info, Just rest for now. I need time to think. -> rest_choice

---

## professional_contact

**Question:** That's a brave and powerful choice. Recognizing you need that level of support is a sign of great strength. A member of our care team will reach out to you in 72 hours to discuss scheduling a call with a professional. Would you like to leave some feedback in your own words? My team would love to hear from you.
**Type:** choice
**Options:** Yes!, No
**Next:** case professional_contact: Yes! -> feedback_request, No -> final_summary

---

## community_group_info

**Question:** That's a wonderful idea. Sometimes, a mother just needs another mother who understands. Our groups are safe, private spaces led by a facilitator/mother where you can share and listen without judgment. Based on your selection, a member of our care team will reach out to you connect you with a group within 72 hours. Would you like to leave some feedback in your own words? My team would love to hear from you.
**Type:** choice
**Options:** Yes!, No
**Next:** case community_group_info: Yes! -> feedback_request, No -> final_summary

---

## rest_choice

**Question:** That is a perfectly wise choice. Listening to your own needs is a beautiful act of self-care. I won't overwhelm you with any more questions or options. You can come back and explore the other options anytime; I'm always here if you need me. Would you like to leave some feedback in your own words?
**Type:** choice
**Options:** Yes!, No
**Next:** case rest_choice: Yes! -> feedback_request, No -> final_summary

---

## pl_opening

**Question:** {name}, I'm so sorry. What you're carrying right now is one of the heaviest things any mother can hold. There is no right or wrong way to feel after a loss like this. I'm here, and I'm not going anywhere. Would it be okay for me to ask you a few gentle questions? You can stop at any point, and there are no wrong answers.
**Type:** choice
**Options:** Yes I'm okay to continue, Not right now
**Next:** case pl_opening: Yes I'm okay to continue -> pl_loss_timing, Not right now -> pl_nurse_offer

---

## pl_nurse_offer

**Question:** Of course. You don't have to do anything you're not ready for. Before you go, please know that our care team is here for you. A nurse can reach out to you personally if you'd like - someone who understands what loss feels like. Would that be okay?
**Type:** choice
**Options:** Yes please reach out to me, Not right now thank you
**Next:** case pl_nurse_offer: Yes please reach out to me -> pl_nurse_confirmed, Not right now thank you -> pl_crisis_number

---

## pl_nurse_confirmed

**Question:** Thank you. Someone from our team will be in touch with you very soon. You are not alone in this.
**Type:** summary
**Next:** nil

---

## pl_crisis_number

**Question:** I understand. Please save this number in case you ever need to talk to someone outside of our team: 0800678678. I'm here whenever you're ready to come back.
**Type:** summary
**Next:** nil

---

## pl_loss_timing

**Question:** Thank you for trusting me with this. Can I ask - how long ago did the loss happen?
**Type:** choice
**Options:** Very recently - within the past few weeks, A few months ago, It has been a while but I still carry it every day
**Next:** pl_physical_check

---

## pl_physical_check

**Question:** I'm so sorry. Before I ask anything else - how are you feeling in your body right now? Sometimes grief affects us physically too.
**Type:** choice
**Options:** I'm okay physically, I haven't been feeling well physically
**Next:** pl_grief_indicators

---

## pl_grief_indicators

**Question:** I'd like to understand a little more about how you have been since the loss. From the following, which feels most true for you right now? You can choose more than one.
**Type:** multi_choice
**Options:** I find it very hard to accept that this happened, I feel numb - like I am just going through the motions of daily life, I feel a great deal of guilt - like I could have done something differently, I have been avoiding places or people or things that remind me of the loss, I am having trouble taking care of myself or my other children or my home, I feel like a part of me is missing and it will never come back, I have moments where I forget and then I remember again - and it hits me all over again, None of these feel true for me right now
**Next:** pl_safety_screen

---

## pl_safety_screen

**Question:** Thank you for sharing that with me. I have one more important question to ask, and I need you to answer as honestly as you can - because I care about your safety. The thought of harming myself has occurred to me.
**Type:** choice
**Options:** Yes quite often, Sometimes, Hardly ever, Never
**Next:** case pl_safety_screen: Yes quite often -> safety_protocol, Sometimes -> safety_protocol, Hardly ever -> safety_protocol, Never -> pl_route_a

---

## pl_route_a

**Question:** Grief after pregnancy loss doesn't have a timeline, and carrying it alongside daily life takes real strength. The fact that you still feel this is not weakness - it is love with nowhere to go yet. There is something small you can try whenever the grief visits, if you'd like.
**Type:** choice
**Options:** Yes show me, Not right now that's okay
**Next:** case pl_route_a: Yes show me -> pl_route_a_exercise, Not right now that's okay -> pl_route_a_skip

---

## pl_route_a_exercise

**Question:** Place one hand over your heart. Take a slow breath in. Say to yourself quietly: "This loss was real. My love for this baby was real. And I am allowed to grieve." That's it - just that, as many times as you need. Whenever you're ready, say okay and we'll continue.
**Type:** text
**Next:** pl_epds_transition

---

## pl_route_a_skip

**Question:** That is a perfectly good choice. I'm here whenever you need me. Whenever you're ready, say okay and we'll continue.
**Type:** text
**Next:** pl_epds_transition

---

## pl_route_b

**Question:** {name}, what you've shared tells me you are in a really difficult place right now. That makes complete sense - grief after pregnancy loss is one of the most painful experiences a person can go through, and you are in the thick of it. Our care team includes a nurse who has been trained specifically to support mothers through loss. She would very much like to reach out to you personally. Would that be okay?
**Type:** choice
**Options:** Yes please reach out to me, Not right now
**Next:** case pl_route_b: Yes please reach out to me -> pl_route_b_confirmed, Not right now -> pl_route_b_declined

---

## pl_route_b_confirmed

**Question:** Thank you. Someone from our team will be in touch with you very soon. You do not have to carry this alone. Whenever you're ready, say okay and we'll continue.
**Type:** text
**Next:** pl_epds_transition

---

## pl_route_b_declined

**Question:** I understand. I will be here whenever you are ready to talk more. Before we continue, please know that you can always save this number in case you need someone: 0800678678. Whenever you're ready, say okay and we'll continue.
**Type:** text
**Next:** pl_epds_transition

---

## pl_route_c

**Question:** {name}, I want to be honest with you. What you've described sounds like grief that has become very heavy - heavier than you should carry alone. This is not weakness. It is a sign that you need and deserve more support than most people around you can offer. I am going to let our care team know that you need to speak with someone soon. A nurse will reach out to you personally. Is there someone close to you - a partner, family member, or friend - who knows what you have been going through?
**Type:** choice
**Options:** Yes I have someone I can lean on, Not really - I have mostly been carrying this alone
**Next:** case pl_route_c: Yes I have someone I can lean on -> pl_route_c_supported, Not really - I have mostly been carrying this alone -> pl_route_c_alone

---

## pl_route_c_supported

**Question:** I'm glad you have that person. Please lean on them. And our nurse will also be in touch with you very soon - you will hear from us. Whenever you're ready, say okay and we'll continue.
**Type:** text
**Next:** pl_epds_transition

---

## pl_route_c_alone

**Question:** Then our team will make sure you hear from someone soon. Please call this number if you need to talk before we reach you: 0800678678. You will not be alone with this. Whenever you're ready, say okay and we'll continue.
**Type:** text
**Next:** pl_epds_transition

---

## pl_epds_transition

**Question:** Before we finish, I'd also like to ask you a few questions about how you have been feeling more generally over the past week. Grief and mood often travel together, and this helps our care team understand the full picture so they can support you better. Is that okay?
**Type:** choice
**Options:** Yes let's continue, Not right now
**Next:** case pl_epds_transition: Yes let's continue -> epds_q1, Not right now -> checkout_point

---

## bp_proxy_flag_pl

**Question:** Thank you for telling me that. The symptom you mentioned is something I want our care team to know about, just to be safe. A nurse will be in touch with you about this. Whenever you're ready, say okay and we'll continue.
**Type:** text
**Next:** checkout_point

---

## bp_proxy_normal_pl

**Question:** Thank you - you haven't flagged any concerning physical symptoms, which is reassuring. Whenever you're ready, say okay and we'll continue.
**Type:** text
**Next:** checkout_point

---

## bp_intro

**Question:** I'm glad you mentioned that. Let's take care of your physical health first - then we'll check in on how you've been feeling emotionally too. Do you have a blood pressure monitor at home?
**Type:** choice
**Options:** Yes I have one, No I don't have one
**Next:** case bp_intro: Yes I have one -> bp_systolic, No I don't have one -> bp_proxy_q1

---

## bp_systolic

**Question:** Please take your reading now if you haven't already. Sit quietly with your arm resting at heart level. When you're ready, tell me the top number first. What is your top number (systolic)? [For example: 120]
**Type:** number
**Next:** bp_diastolic

---

## bp_diastolic

**Question:** And the bottom number (diastolic)? [For example: 80]
**Type:** number
**Next:** bp_normal

---

## bp_emergency

**Question:** {name}, I need to stop our check-in right now. Your blood pressure reading is in a range that needs immediate medical attention - please do not wait. Please go to the Emergency Department at Ho Teaching Hospital right away. If you cannot get there, go to the nearest hospital. Do not drive yourself. Do not wait to see if it improves. Can someone take you now?
**Type:** choice
**Options:** Yes I'm going now, I'm not sure / I need help getting there
**Next:** case bp_emergency: Yes I'm going now -> bp_emergency_going, I'm not sure / I need help getting there -> bp_emergency_help

---

## bp_emergency_going

**Question:** Please go immediately. Our team will be notified right now and a nurse will follow up with you as soon as possible. You have done exactly the right thing today.
**Type:** summary
**Next:** nil

---

## bp_emergency_help

**Question:** Please call this number and tell them your blood pressure reading: 112. Our team is being alerted right now. You are not alone.
**Type:** summary
**Next:** nil

---

## bp_concern

**Question:** {name}, your reading is a little higher than the normal range. It is not an emergency right now, but it is something our team needs to know about. A nurse from our care team will call you within 24 hours to discuss this with you. While you wait to hear from us, please watch for any of these warning signs - and if any of them appear, go to the hospital immediately without waiting for our call: severe headache, blurred vision or seeing spots, swelling in your face or hands, severe pain just under your ribs, or difficulty breathing. Now, while we wait for the team to reach you, I'd also like to check in on how you've been feeling emotionally. That's just as important. Would that be okay?
**Type:** choice
**Options:** Yes let's continue, Not right now
**Next:** case bp_concern: Yes let's continue -> bp_emotional_options, Not right now -> checkout_point

---

## bp_normal

**Question:** That's a reassuring reading - well within the normal range. It's great that you're keeping an eye on it. Now let's also check in on how you've been feeling emotionally. That's just as important as your physical health. Would that be okay?
**Type:** choice
**Options:** Yes let's continue, Not right now
**Next:** case bp_normal: Yes let's continue -> bp_emotional_options, Not right now -> checkout_point

---

## bp_emotional_options

**Question:** Thank you, {name}. What exactly is your concern today?
**Type:** choice
**Options:** I feel sad or disconnected from my baby, My baby's in the NICU, I'm stressed and anxious
**Next:** case bp_emotional_options: I feel sad or disconnected from my baby -> sad_disconnected_intro, My baby's in the NICU -> nicu_concern, I'm stressed and anxious -> stress_anxiety_intro

---

## bp_proxy_q1

**Question:** No problem. I'm going to ask you a few questions about how your body has been feeling instead. Please answer based on the past 24 hours. Have you had a headache that felt unusually severe - worse than your normal headaches, or one that came on suddenly and strongly?
**Type:** choice
**Options:** Yes, No
**Next:** bp_proxy_q2

---

## bp_proxy_q2

**Question:** Have you noticed any changes in your vision - such as blurriness, seeing spots, or flashing lights?
**Type:** choice
**Options:** Yes, No
**Next:** bp_proxy_q3

---

## bp_proxy_q3

**Question:** Have you noticed unusual swelling in your face, hands, or feet - more than you would normally expect?
**Type:** choice
**Options:** Yes, No
**Next:** bp_proxy_q4

---

## bp_proxy_q4

**Question:** Have you had severe pain in your upper abdomen or just under your ribs on the right side?
**Type:** choice
**Options:** Yes, No
**Next:** bp_proxy_q5

---

## bp_proxy_q5

**Question:** Have you had any difficulty breathing that is new or unusual for you?
**Type:** choice
**Options:** Yes, No
**Next:** bp_proxy_normal

---

## bp_proxy_emergency

**Question:** {name}, I need to pause here. What you have described are warning signs that need urgent medical attention. I need you to go to the Emergency Department at Ho Teaching Hospital right now - or the nearest hospital if you cannot get there. Please do not wait. Can someone take you to the hospital now?
**Type:** choice
**Options:** Yes I'm going now, I need help getting there
**Next:** case bp_proxy_emergency: Yes I'm going now -> bp_proxy_emergency_going, I need help getting there -> bp_proxy_emergency_help

---

## bp_proxy_emergency_going

**Question:** Please go immediately. Our team will be notified right now. You have done the right thing today.
**Type:** summary
**Next:** nil

---

## bp_proxy_emergency_help

**Question:** Please call 112 right now and describe your symptoms. Our team is being alerted.
**Type:** summary
**Next:** nil

---

## bp_proxy_flag

**Question:** Thank you for telling me that. The symptom you mentioned is something I want our care team to know about, just to be safe. A nurse will be in touch with you about this. While we get that sorted, I'd also like to check in on how you've been feeling emotionally. Would that be okay?
**Type:** choice
**Options:** Yes let's continue, Not right now
**Next:** case bp_proxy_flag: Yes let's continue -> bp_emotional_options, Not right now -> checkout_point

---

## bp_proxy_normal

**Question:** Thank you - you haven't flagged any concerning physical symptoms, which is reassuring. It's good to check in like this. Now let's also check in on how you've been feeling emotionally. Would that be okay?
**Type:** choice
**Options:** Yes let's continue, Not right now
**Next:** case bp_proxy_normal: Yes let's continue -> bp_emotional_options, Not right now -> checkout_point

---

## feedback_request

**Question:** My team would appreciate your feedback. Can you tell us what you think about Eli?
**Type:** text
**Next:** final_summary

---

## final_summary

**Question:** Thank you for your time and trust today. Take care of yourself, mama. Bye.
**Type:** summary
**Next:** nil

---
