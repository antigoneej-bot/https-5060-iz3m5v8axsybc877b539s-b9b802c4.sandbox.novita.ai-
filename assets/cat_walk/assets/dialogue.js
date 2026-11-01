// Paired friendly/polite lines. Emotion selections remain browser-session only.
const dialogueGroups={
 sad:['sad','lonely','vulnerable','depressed','excluded','hollow','hurtFeelings'],
 tired:['weary','sleepy','indifferent'],
 angry:['angry','impatient','wronged','sulky','stubborn','cynical','jealous'],
 worried:['cautious','anxious','confused','hesitant','dread'],
 self:['selfCritical','ashamed','inferior','guilty'],
 happy:['proud','joyful','affectionate','excited','grateful'],
 calm:['nostalgic','focused','curious','enchanted','serene','content']
};
const dialogueLines={
 sad:[['이 또한 지나갈 거야. 오늘은 내가 곁에 있을게.','이 또한 지나갈 거예요. 오늘은 제가 곁에 있을게요.'],['슬픈 날에는 억지로 웃지 않아도 괜찮아.','슬픈 날에는 억지로 웃지 않아도 괜찮아요.'],['말하고 싶지 않으면 조용히 같이 걷자.','말하고 싶지 않으면 조용히 같이 걸어요.'],['오늘 내 곁에 와줘서 고마워.','오늘 제 곁에 와줘서 고마워요.']],
 tired:[['힘들었지? 오늘은 천천히 가도 괜찮아.','힘드셨죠? 오늘은 천천히 가도 괜찮아요.'],['너는 잘하고 있어. 잠깐 쉬어도 괜찮아.','잘하고 계세요. 잠깐 쉬어도 괜찮아요.'],['졸리면 나랑 나란히 햇볕 쬐자.','졸리면 저랑 나란히 햇볕 쬐어요.'],['오늘도 여기까지 오느라 애썼어.','오늘도 여기까지 오느라 애쓰셨어요.']],
 angry:[['속상하고 화났구나. 내가 옆에서 들어줄게.','속상하고 화나셨군요. 제가 옆에서 들어줄게요.'],['이 또한 지나갈 거야. 지금은 천천히 같이 걷자.','이 또한 지나갈 거예요. 지금은 천천히 같이 걸어요.'],['오늘은 착한 말만 하려고 애쓰지 않아도 돼.','오늘은 착한 말만 하려고 애쓰지 않아도 돼요.'],['마음이 복잡한 날에도 나는 네 편이야.','마음이 복잡한 날에도 저는 당신 편이에요.']],
 worried:[['지금 답을 다 찾지 않아도 괜찮아.','지금 답을 다 찾지 않아도 괜찮아요.'],['우리 일단 이 꽃길 한 걸음만 걸어볼까?','우리 일단 이 꽃길 한 걸음만 걸어볼까요?'],['너는 잘하고 있어. 서두르지 않아도 돼.','잘하고 계세요. 서두르지 않아도 돼요.'],['걱정이 많은 날엔 내가 보폭을 맞춰줄게.','걱정이 많은 날엔 제가 보폭을 맞춰줄게요.']],
 self:[['완벽하지 않아도 너는 소중해.','완벽하지 않아도 당신은 소중해요.'],['너는 잘하고 있어. 오늘 한 작은 일도 기억해 줘.','잘하고 계세요. 오늘 한 작은 일도 기억해 주세요.'],['오늘은 너 자신에게도 조금 다정해 줘.','오늘은 자신에게도 조금 다정해 주세요.'],['실수한 날에도 같이 산책할 자리는 있어.','실수한 날에도 같이 산책할 자리는 있어요.']],
 happy:[['너는 웃을 때가 제일 예뻐. 나도 기분 좋아!','웃을 때가 제일 예뻐요. 저도 기분 좋아요!'],['오늘의 좋은 마음, 나랑 나눠줘서 고마워.','오늘의 좋은 마음, 저랑 나눠줘서 고마워요.'],['사랑해. 함께 걸으니까 더 신난다!','사랑해요. 함께 걸으니까 더 신나요!'],['오늘은 발걸음까지 폴짝폴짝이야!','오늘은 발걸음까지 폴짝폴짝이에요!']],
 calm:[['이 바람 좋다. 조금만 더 같이 걷자.','이 바람 좋아요. 조금만 더 같이 걸어요.'],['아무 말 없이 같이 있어도 참 좋아.','아무 말 없이 같이 있어도 참 좋아요.'],['오늘의 작은 반짝임을 같이 찾아볼까?','오늘의 작은 반짝임을 같이 찾아볼까요?'],['이 조용한 시간을 함께해 줘서 고마워.','이 조용한 시간을 함께해 줘서 고마워요.']],
 affection:[['같이 산책해 줘서 고마워.','같이 산책해 주셔서 고마워요.'],['사랑해. 네 곁이 참 포근해.','사랑해요. 곁에 있으니 참 포근해요.'],['네가 내 이름을 불러주면 꼬리가 저절로 움직여.','제 이름을 불러주시면 꼬리가 저절로 움직여요.'],['오늘도 나랑 함께해 줘서 기뻐.','오늘도 저랑 함께해 주셔서 기뻐요.']],
 playful:[['나 배고파… 산책하고 간식 하나 먹을까?','저 배고파요… 산책하고 간식 하나 먹을까요?'],['나 오늘 많이 걸었는데… 추루 하나면 좋겠다냥.','저 오늘 많이 걸었는데… 추루 하나면 좋겠어요, 냥.'],['흥, 꽃만 보지 말고 내 귀여운 발도 봐줘!','흥, 꽃만 보지 말고 제 귀여운 발도 봐주세요!'],['조금만 더 같이 있고 싶은데… 꼬리 한 번만 쓰다듬어 줘.','조금만 더 같이 있고 싶은데… 꼬리 한 번만 쓰다듬어 주세요.']]
};
let recentDialogue=[],nextChatAt=2,chatTurn=0;
function dialogueGroup(id){return Object.keys(dialogueGroups).find(k=>dialogueGroups[k].includes(id))||'calm'}
function dialoguePool(indices,ending=false){const groups=[...new Set(indices.map(i=>dialogueGroup(EMOTIONS[i]?.id)))];const difficult=groups.filter(g=>['sad','tired','angry','worried','self'].includes(g));const chosen=difficult.length?difficult:groups;let pool=chosen.flatMap(g=>dialogueLines[g]);if(!pool.length)pool=[...dialogueLines.calm];if(!ending&&chatTurn%3===2)pool=difficult.length?dialogueLines.affection:[...dialogueLines.affection,...dialogueLines.playful];return pool}
function catMessage(indices=[...selected],ending=false){const pool=dialoguePool(indices,ending);let available=pool.filter(p=>!recentDialogue.includes(p[0]));if(!available.length){recentDialogue=recentDialogue.slice(-1);available=pool.filter(p=>!recentDialogue.includes(p[0]));}const pair=available[Math.floor(Math.random()*available.length)]||pool[0];recentDialogue.push(pair[0]);recentDialogue=recentDialogue.slice(-10);chatTurn++;const polite=person.style==='polite'||/(님|씨)$/.test(person.nickname.trim());const n=address(person.nickname,person.style);return(n?n+',\n':'')+pair[polite?1:0]}
function walkChat(m){if(elapsed<nextChatAt||specialReaction()||elapsed<toastUntil)return;announce(catMessage(m===undefined?[...selected]:[m]));nextChatAt=elapsed+8+Math.random()*3}
