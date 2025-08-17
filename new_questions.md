# Eli Mental Health Support Bot Configuration

This file defines the questions and flow for Eli, a mental health support chatbot for mothers.

## start

**Question:** Hey there! I'm Eli. You can think of me as a friend. I'm designed to help women on their parenting journeys who may be experiencing mental distress. I can help with simple exercises specifically relevant to your challenges. And if you prefer, I can connect you with other mothers who can relate with your experiences or some professionals later. I'm really glad you reached out. What should I call you?
**Type:** text
**Next:** privacy_intro

---

## privacy_intro

**Question:** Nice to meet you, {name}. I'm here to listen and support you. Before we start, I need to ask for a couple of details to personalize your experience. Your privacy is my highest priority. I will only ask for information when it's needed to help you, and you can always choose to skip a question. Everything you share is kept private and secure. You can read our full Privacy Policy here at any time. How old are you? [For example: 32]
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

**Question:** Thanks so much for your patience {name}. Now let's talk about why you're here. What stage of parenthood are you?
**Type:** choice
**Options:** I'm a nursing mother
**Next:** case parenthood_stage: I'm a nursing mother -> nursing_mother_concerns

---

## nursing_mother_concerns

**Question:** {name}, i want you to know that the journey of a nursing mother is its own unique world, with its own joys and its own heavy days. I'm here for all of it. What exactly is your concern today?
**Type:** choice
**Options:** I feel sad or disconnected from my baby, My baby's in the NICU, I'm stressed and anxious
**Next:** case nursing_mother_concerns: I feel sad or disconnected from my baby -> sad_disconnected_intro, My baby's in the NICU -> nicu_concern, I'm stressed and anxious -> stress_anxiety_intro

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
**Next:** case professional_contact: Yes -> feedback_request, No -> final_summary

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
**Options:** Yes!, No
**Next:** case rest_choice: Yes! -> feedback_request, No -> final_summary

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
