## start

**Question:** Hey there! I'm Eli. I'm really glad you reached out. What should I call you?

**Type:** text

**Next:** location_age

---

## location_age

**Question:** Nice to meet you, {name}. I'm here to listen and support however feels right for you. Can you tell me roughly where you're located and your age? This just helps me connect you with local resources if you'd like them later.

**Type:** text

**Next:** cultural_background

---

## cultural_background

**Question:** Thanks. One more thing - how would you describe your cultural background? I ask because I focus on supporting women from African descent communities, and I want to make sure I understand your experience.

**Type:** choice

**Options:** Ghanaian, Nigerian, Other West African, East African, Caribbean, African-American, Other

**Next:** mental_health_experience

---

## mental_health_experience

**Question:** Perfect. And have you ever talked to a mental health professional before, or used apps like this?

**Type:** choice

**Options:** Yes I've talked to someone, Yes I've used apps, No this is my first time, Prefer not to say

**Next:** phone_followup

---

## phone_followup

**Question:** Got it. There's no judgment either way - I just want to meet you where you are. Would you like me to check in with you in a few weeks? I can text you a quick follow-up if you share your number, but totally optional.

**Type:** choice

**Options:** Yes please check in, No thanks, Maybe later

**Next:** emotional_consent

---

## emotional_consent

**Question:** Would you like to check in with how you're feeling today?

**Type:** choice

**Options:** Yes let's check in, Not ready yet, I'm just exploring

**Next:** case emotional_consent: Yes let's check in -> emotion_routing, Not ready yet -> soft_deferral, I'm just exploring -> intro_support

---

## soft_deferral

**Question:** That's totally okay. Take your time. I'm here whenever you're ready. Would you like to explore what kind of support I offer, or come back another time?

**Type:** choice

**Options:** Tell me about your support, I'll come back later

**Next:** case soft_deferral: Tell me about your support -> intro_support, I'll come back later -> summary

---

## intro_support

**Question:** I focus on supporting women through various life challenges - from everyday overwhelm to major life transitions, pregnancy experiences, and mental health struggles. When you're ready to talk, I'm here.

**Type:** summary

**Next:** nil

---

## emotion_routing

**Question:** No pressure - just tell me what feels closest to where you are today:

**Type:** choice

**Options:** I feel overwhelmed or low energy, I feel disconnected from my baby, I feel sad about a loss, My baby's in the NICU, I'm anxious or can't settle, I've been trying to get pregnant, I've had a major health scare and I'm reevaluating everything, None of these fit me

**Next:** case emotion_routing: I feel overwhelmed or low energy -> general_overwhelm, I feel disconnected from my baby -> postpartum_disconnection, I feel sad about a loss -> pregnancy_loss, My baby's in the NICU -> nicu_stress, I'm anxious or can't settle -> anxiety_support, I've been trying to get pregnant -> infertility_support, I've had a major health scare and I'm reevaluating everything -> health_scare_identity, None of these fit me -> fallback_support

---

## general_overwhelm

**Question:** Hey mama. I'm really glad you reached out. No pressure—just tell me what kind of day it's been.

**Type:** choice

**Options:** It's been okay, It's been a lot, Not sure yet

**Next:** case general_overwhelm: It's been a lot -> overwhelm_wellbeing, It's been okay -> overwhelm_wellbeing, Not sure yet -> overwhelm_wellbeing

---

## overwhelm_wellbeing

**Question:** Thank you for sharing that. When days feel heavy, it helps to pause. On a scale of 1 to 10, how would you say your overall wellbeing has been this past week?

**Type:** choice

**Options:** 1-3 really struggling, 4-6 getting by, 7-10 doing okay overall

**Next:** overwhelm_explore

---

## overwhelm_explore

**Question:** Thanks for letting me know. Would you like to unpack what's felt hardest today—or just sit together for a moment?

**Type:** choice

**Options:** I'll talk about it, Let's just pause, Not now

**Next:** case overwhelm_explore: I'll talk about it -> overwhelm_type, Let's just pause -> grounding_exercise, Not now -> check_feeling_now

---

## overwhelm_type

**Question:** I'm here. Was it more about emotions, something that happened, or feeling disconnected?

**Type:** choice

**Options:** Emotions, Something happened, Disconnected

**Next:** case overwhelm_type: Disconnected -> disconnection_impact, Emotions -> emotional_impact, Something happened -> event_impact

---

## disconnection_impact

**Question:** That's more common than we talk about. You're doing so much—no wonder it's hard to feel present. How much has this been affecting your daily life - things like work, relationships, or taking care of yourself?

**Type:** choice

**Options:** Not at all, A little, Quite a bit, A lot

**Next:** case disconnection_impact: Quite a bit -> grounding_offer, A lot -> grounding_offer, A little -> grounding_offer, Not at all -> grounding_offer

---

## grounding_offer

**Question:** Disconnection can feel scary, but it's often your mind's way of protecting you when you're stretched thin. Would you like to try a grounding reflection or just be here?

**Type:** choice

**Options:** Try reflection, Just be here

**Next:** case grounding_offer: Try reflection -> grounding_exercise, Just be here -> check_feeling_now

---

## grounding_exercise

**Question:** Okay. Let's start simple. Place one hand on your chest, one on your belly. Feel yourself breathing. You're here. You're doing enough. Even when it doesn't feel like it. Take three slow breaths with me. How was that?

**Type:** choice

**Options:** That helped, I need something else, Continue

**Next:** check_feeling_now

---

## postpartum_disconnection

**Question:** That can be such a lonely feeling—especially when everyone expects you to be smiling. You're not alone. If you don't mind me asking, on a scale of 1-10, how has your overall wellbeing felt this past week?

**Type:** choice

**Options:** 1-3 really struggling, 4-6 getting by, 7-10 doing okay overall

**Next:** postpartum_duration

---

## postpartum_duration

**Question:** Thank you for sharing that. Can I ask: has it felt this way for a few days or more like a few weeks?

**Type:** choice

**Options:** A few days, A few weeks, Not sure

**Next:** postpartum_impact

---

## postpartum_impact

**Question:** Sometimes our minds go into protection mode after birth. How much has this been affecting things like taking care of yourself, connecting with others, or daily tasks?

**Type:** choice

**Options:** Not at all, A little, Quite a bit, A lot

**Next:** postpartum_checkin_offer

---

## postpartum_checkin_offer

**Question:** Would it feel okay if we checked in more deeply?

**Type:** choice

**Options:** Yes I'd like that, Not right now, Tell me more

**Next:** case postpartum_checkin_offer: Yes I'd like that -> postpartum_screening, Tell me more -> postpartum_screening_explain, Not right now -> check_feeling_now

---

## postpartum_screening_explain

**Question:** Just a few questions—nothing heavy. Some moms notice sadness, numbness, or guilt. Would you like to see if any of that sounds familiar?

**Type:** choice

**Options:** Okay let's try it, I'll come back later

**Next:** case postpartum_screening_explain: Okay let's try it -> postpartum_screening, I'll come back later -> summary

---

## postpartum_screening

**Question:** In the past week, have you been able to enjoy things the way you used to?

**Type:** choice

**Options:** Yes, No, Not sure

**Next:** postpartum_irritability

---

## postpartum_irritability

**Question:** Have you been feeling more irritable or angry than usual?

**Type:** choice

**Options:** Yes, No, Sometimes

**Next:** postpartum_sleep

---

## postpartum_sleep

**Question:** And sleeping when you have the chance to sleep?

**Type:** choice

**Options:** Yes I sleep okay, No my mind races, I sleep too much

**Next:** postpartum_appetite

---

## postpartum_appetite

**Question:** Have you been able to eat regularly?

**Type:** choice

**Options:** Yes, No no appetite, I eat too much

**Next:** postpartum_support_message

---

## postpartum_support_message

**Question:** Thank you for trusting me with all of this. It sounds like your body and mind are working really hard right now. What you're describing sounds like postpartum depression, which is treatable and you're not alone in it. You deserve support.

**Type:** summary

**Next:** check_feeling_now

---

## pregnancy_loss

**Question:** I'm so sorry. There are no perfect words, but I'm here. However you're feeling—sad, numb, angry—it all belongs. If it's okay to ask, how would you rate your overall wellbeing this past week, from 1-10?

**Type:** choice

**Options:** 1-3 really struggling, 4-6 getting by, 7-10 doing okay overall

**Next:** loss_talk_offer

---

## loss_talk_offer

**Question:** Thank you for trusting me with that. Would you like to talk about how you've been feeling, or just be here quietly?

**Type:** choice

**Options:** I'd like to talk, Just needed to say it, Not sure

**Next:** case loss_talk_offer: I'd like to talk -> loss_feelings, Just needed to say it -> check_feeling_now, Not sure -> check_feeling_now

---

## loss_feelings

**Question:** How have your days been feeling since then?

**Type:** choice

**Options:** Heavy, Numb, A mix, I don't know

**Next:** loss_impact

---

## loss_impact

**Question:** How much has this been affecting your daily life - work, relationships, taking care of yourself?

**Type:** choice

**Options:** Not at all, A little, Quite a bit, A lot

**Next:** loss_heaviest

---

## loss_heaviest

**Question:** Grief touches everything, doesn't it? Would it help to name what's felt heaviest or do a quiet reflection together?

**Type:** choice

**Options:** Name it, Reflect quietly, Not now

**Next:** case loss_heaviest: Name it -> loss_hardest_part, Reflect quietly -> loss_reflection, Not now -> check_feeling_now

---

## loss_hardest_part

**Question:** What's been the hardest part to carry?

**Type:** choice

**Options:** The sadness, Feeling empty, People not understanding, Blaming myself

**Next:** case loss_hardest_part: Blaming myself -> self_blame_response, The sadness -> grief_validation, Feeling empty -> grief_validation, People not understanding -> grief_validation

---

## self_blame_response

**Question:** Oh honey. Miscarriage is never your fault. Your body didn't fail—sometimes things just happen that are beyond anyone's control. But I know that knowing it in your head doesn't stop your heart from hurting. Have you been able to be gentle with yourself at all, or has it felt like you're fighting yourself?

**Type:** choice

**Options:** I'm trying to be gentle, I'm fighting myself, I don't know how to be gentle

**Next:** case self_blame_response: I'm fighting myself -> self_compassion_exercise, I'm trying to be gentle -> check_feeling_now, I don't know how to be gentle -> self_compassion_exercise

---

## self_compassion_exercise

**Question:** That fight is exhausting on top of grief. Can we try something small to soften that inner voice? Put your hand on your heart. Say this with me: "I did nothing wrong. I am worthy of kindness, especially from myself."

**Type:** choice

**Options:** That felt good, That was hard, I couldn't say it

**Next:** check_feeling_now

---

## nicu_stress

**Question:** That's so much to hold. Many moms feel like they're suspended between hope and fear. If you don't mind sharing, how would you rate your overall wellbeing this past week, from 1-10?

**Type:** choice

**Options:** 1-3 really struggling, 4-6 getting by, 7-10 doing okay overall

**Next:** nicu_talk_offer

---

## nicu_talk_offer

**Question:** Would it help to talk about what's been hardest, or pause and breathe?

**Type:** choice

**Options:** Talk about it, Just breathe, I don't know

**Next:** case nicu_talk_offer: Talk about it -> nicu_hardest, Just breathe -> breathing_exercise, I don't know -> breathing_exercise

---

## nicu_hardest

**Question:** I'm here. Is it more the waiting, the worry, or missing physical closeness?

**Type:** choice

**Options:** Waiting, Worry, I miss holding my baby

**Next:** case nicu_hardest: I miss holding my baby -> nicu_bonding_response, Waiting -> nicu_impact, Worry -> nicu_impact

---

## nicu_bonding_response

**Question:** That ache is real. Touch is part of bonding—and when it's interrupted, your heart still reaches. How much has all of this been affecting your daily life - sleep, eating, connecting with others?

**Type:** choice

**Options:** Not at all, A little, Quite a bit, A lot

**Next:** nicu_support_offer

---

## nicu_support_offer

**Question:** Want to reflect quietly or find someone to talk to?

**Type:** choice

**Options:** Reflect quietly, Help me find someone, Not now

**Next:** case nicu_support_offer: Reflect quietly -> nicu_reflection, Help me find someone -> next_steps, Not now -> check_feeling_now

---

## nicu_reflection

**Question:** Okay. Let's sit here, breathe, and remind your body—you're doing your best. Even from a distance, your love reaches your baby. Just for now, that's enough. How was that?

**Type:** choice

**Options:** That helped, I need more, That made me cry

**Next:** case nicu_reflection: That made me cry -> crying_validation, That helped -> check_feeling_now, I need more -> check_feeling_now

---

## crying_validation

**Question:** Tears are okay here. Sometimes love is so big it spills over. Your baby is lucky to have a mom who loves them this much.

**Type:** summary

**Next:** check_feeling_now

---

## anxiety_support

**Question:** That sounds exhausting—like your body's on high alert. If you don't mind me asking, how would you rate your overall wellbeing this past week, from 1-10?

**Type:** choice

**Options:** 1-3 really struggling, 4-6 getting by, 7-10 doing okay overall

**Next:** anxiety_tension_check

---

## anxiety_tension_check

**Question:** Would it help to check where you're feeling that tension?

**Type:** choice

**Options:** Yes, Not right now, What do you mean

**Next:** case anxiety_tension_check: Yes -> tension_location, What do you mean -> tension_location, Not right now -> check_feeling_now

---

## tension_location

**Question:** Where have you been noticing it lately?

**Type:** choice

**Options:** Chest, Jaw or neck, In my thoughts, I'm not sure

**Next:** case tension_location: In my thoughts -> racing_thoughts, Chest -> anxiety_impact, Jaw or neck -> anxiety_impact, I'm not sure -> anxiety_impact

---

## racing_thoughts

**Question:** Racing thoughts can spiral fast. How much has this been affecting your daily life - work, relationships, taking care of yourself?

**Type:** choice

**Options:** Not at all, A little, Quite a bit, A lot

**Next:** grounding_offer_anxiety

---

## grounding_offer_anxiety

**Question:** When your mind races, everything else gets harder. Would you like to try a small grounding exercise to slow the spiral?

**Type:** choice

**Options:** Yes let's try, Not now

**Next:** case grounding_offer_anxiety: Yes let's try -> grounding_321, Not now -> check_feeling_now

---

## grounding_321

**Question:** Okay. Name 3 things you can see, 2 you can touch, 1 you can hear. That's it. No fixing—just arriving here. How was that?

**Type:** choice

**Options:** That helped, I'm still spinning, I couldn't focus

**Next:** anxiety_triggers

---

## anxiety_triggers

**Question:** Do you know what tends to trigger the racing thoughts, or do they seem to come out of nowhere?

**Type:** choice

**Options:** I know some triggers, They come out of nowhere, I'm not sure

**Next:** check_feeling_now

---

## infertility_support

**Question:** That's such a long time to carry hope. Whatever you're feeling is valid. If it's okay to ask, how would you rate your overall wellbeing this past week, from 1-10?

**Type:** choice

**Options:** 1-3 really struggling, 4-6 getting by, 7-10 doing okay overall

**Next:** infertility_feelings_offer

---

## infertility_feelings_offer

**Question:** Would it help to name what's hardest, or sit with it quietly?

**Type:** choice

**Options:** Name it, Sit with it, I don't know

**Next:** case infertility_feelings_offer: Name it -> infertility_feelings, Sit with it -> check_feeling_now, I don't know -> check_feeling_now

---

## infertility_feelings

**Question:** What feels closest to what you're holding today?

**Type:** choice

**Options:** I feel broken, I'm angry, I'm tired, I'm numb

**Next:** case infertility_feelings: I feel broken -> broken_response, I'm angry -> infertility_impact, I'm tired -> infertility_impact, I'm numb -> infertility_impact

---

## broken_response

**Question:** That feeling is real—but you are not broken. Your worth is not defined by this. How much has this been affecting your daily life - work, relationships, taking care of yourself?

**Type:** choice

**Options:** Not at all, A little, Quite a bit, A lot

**Next:** infertility_reflection_offer

---

## infertility_reflection_offer

**Question:** Infertility touches everything, doesn't it? Would a short reflection help right now?

**Type:** choice

**Options:** Yes please, Not now

**Next:** case infertility_reflection_offer: Yes please -> infertility_reflection, Not now -> infertility_support_check

---

## infertility_reflection

**Question:** Okay. Say this silently or aloud: "My body is not my enemy. I'm still whole." You're doing enough. How did that feel?

**Type:** choice

**Options:** That felt good, That was hard to say, I don't believe it yet

**Next:** infertility_support_check

---

## infertility_support_check

**Question:** Are you getting support through this journey, or has it felt lonely?

**Type:** choice

**Options:** I have some support, It's been really lonely, Mixed

**Next:** check_feeling_now

---

## health_scare_identity

**Question:** That makes so much sense. Sometimes recovery starts when the treatment ends. If you don't mind sharing, how would you rate your overall wellbeing this past week, from 1-10?

**Type:** choice

**Options:** 1-3 really struggling, 4-6 getting by, 7-10 doing okay overall

**Next:** identity_reflection_offer

---

## identity_reflection_offer

**Question:** Want to reflect on what's changed—or do a mental health check-in?

**Type:** choice

**Options:** Reflect, Check in, Not sure

**Next:** case identity_reflection_offer: Reflect -> identity_values, Check in -> check_feeling_now, Not sure -> check_feeling_now

---

## identity_values

**Question:** What's something you used to value—but now you're questioning?

**Type:** choice

**Options:** My job, My relationships, My goals, I'm not sure

**Next:** identity_impact

---

## identity_impact

**Question:** How much has this uncertainty been affecting your daily life - sleep, energy, connecting with others?

**Type:** choice

**Options:** Not at all, A little, Quite a bit, A lot

**Next:** identity_reset_offer

---

## identity_reset_offer

**Question:** Big health scares have a way of rearranging our priorities, don't they? Would you like a mental reset tool or someone to talk to?

**Type:** choice

**Options:** Mental reset, Find someone, Not now

**Next:** case identity_reset_offer: Mental reset -> identity_reset, Find someone -> next_steps, Not now -> check_feeling_now

---

## identity_reset

**Question:** Okay. Place one hand on your chest, the other on your belly. Breathe in. Say: "I survived. I'm allowed to choose differently now." How was that?

**Type:** choice

**Options:** That felt powerful, That was emotional, I need to sit with that

**Next:** identity_clarity

---

## identity_clarity

**Question:** Is there anything that does feel clear to you right now, even if it's small?

**Type:** choice

**Options:** Yes a few things, Nothing feels clear, I'm not sure

**Next:** check_feeling_now

---

## fallback_support

**Question:** That's okay. Sometimes we need support even when we can't name exactly what we're feeling. Would you like to try some journaling prompts or just talk through what's on your mind?

**Type:** choice

**Options:** Journaling prompts, Talk it through, Not sure

**Next:** check_feeling_now

---

## breathing_exercise

**Question:** Let's take a moment to breathe together. In through your nose for 4 counts, hold for 4, out through your mouth for 6. Just focus on your breath. How was that?

**Type:** choice

**Options:** That helped, I need more, I couldn't focus

**Next:** check_feeling_now

---

## check_feeling_now

**Question:** Thanks for sharing all that with me. Just checking in—how are you feeling now?

**Type:** choice

**Options:** A bit lighter, Still a bit heavy, Not sure yet

**Next:** recommend_question

---

## recommend_question

**Question:** Would you recommend talking with me like this to a friend going through something similar?

**Type:** choice

**Options:** Yes, No, Maybe

**Next:** next_steps

---

## next_steps

**Question:** Would you like to explore one of these next steps?

**Type:** choice

**Options:** Talk to a professional, Join a support group, Just rest for now—I'll check in another day

**Next:** likelihood_check

---

## likelihood_check

**Question:** How likely are you to follow through on this recommendation?

**Type:** choice

**Options:** Very likely, Somewhat likely, Unsure, Unlikely

**Next:** closing_message

---

## closing_message

**Question:** Thank you for trusting me with your feelings today. Remember, you're not alone in this journey. Take care of yourself.

**Type:** summary

**Next:** nil

---

# Emergency Support Protocol

If crisis language is detected, immediately route to emergency support:

## emergency_support

**Question:** I'm really sorry you're feeling this way. You are not alone, and you deserve support that can hold you safely right now. Can I share a few ways to get help immediately?

**Type:** choice

**Options:** Yes please, No not ready, Tell me more first

**Next:** case emergency_support: Yes please -> crisis_resources, No not ready -> crisis_checkin, Tell me more first -> crisis_checkin

---

## crisis_resources

**Question:** Here are people who can help right now: Crisis Text Line: Text HOME to 741741, National Suicide Prevention Lifeline: 988, If you're in immediate danger: Call 911 or go to your nearest emergency room. I'm also still here if you want to keep talking while you reach out to them.

**Type:** choice

**Options:** Talk to someone now, Stay here with Eli, I need a moment

**Next:** summary

---

## crisis_checkin

**Question:** I'm still here if you need to talk. If you're in immediate danger, please contact 988 or someone nearby you trust. You matter, and there are people who want to help.

**Type:** summary

**Next:** nil

---
