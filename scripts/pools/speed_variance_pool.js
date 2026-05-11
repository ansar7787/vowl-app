// Speed Variance: 600 unique phrases for speed/rhythm practice
const getIpa = require(__dirname + '/get_ipa.js');
module.exports = function() {
  const pool = [];
  const starters = [
    'Please remember to','I would like to','Can you help me','We should try to','They decided to',
    'She managed to','He promised to','It is important to','You need to','We must learn to',
    'Let me show you how to','I am planning to','Would you prefer to','The key is to','Try your best to',
    'Make sure you','Do not forget to','Always remember to','Be careful to','Take time to',
    'Allow yourself to','Consider trying to','Focus on how to','Keep working to','Start learning to',
    'Begin planning to','Continue working to','Stop trying to','Avoid failing to','Prepare yourself to',
  ];
  const midParts = [
    'carefully prepare the','quickly finish the','slowly read through the','properly organize the',
    'thoroughly review the','gently handle the','efficiently complete the','accurately measure the',
    'skillfully craft the','patiently explain the','clearly describe the','neatly arrange the',
    'firmly establish the','smoothly transition the','boldly present the','wisely choose the',
    'calmly discuss the','bravely face the','freely express the','safely navigate the',
  ];
  const endings = [
    'final project report before the deadline.','important meeting agenda for tomorrow.',
    'comprehensive study guide for the exam.','detailed budget plan for next quarter.',
    'complete training manual for new staff.','thorough safety inspection checklist.',
    'updated customer feedback analysis.','revised marketing strategy document.',
    'annual performance review summary.','emergency evacuation procedure guide.',
    'weekly progress report for management.','monthly financial statement overview.',
    'quarterly sales projection forecast.','yearly inventory assessment report.',
    'environmental impact assessment study.','product development timeline proposal.',
    'community engagement action plan today.','digital transformation roadmap clearly.',
    'employee wellness program brochure.','international trade agreement draft.',
    'supply chain optimization strategy.','research methodology framework paper.',
    'quality assurance testing protocol.','data privacy compliance checklist.',
    'customer satisfaction survey results.','brand identity guidelines document.',
    'crisis communication response plan.','intellectual property filing records.',
    'cybersecurity threat assessment now.','regulatory compliance audit findings.',
  ];
  const speeds = [
    {name:'Normal',val:1.0,opt:['Normal (1x)','Fast (1.5x)'],ans:0,hint:'Standard speaking rate.'},
    {name:'Fast',val:1.5,opt:['Fast (1.5x)','Slow (0.75x)'],ans:0,hint:'Faster than usual.'},
    {name:'Slow',val:0.75,opt:['Slow (0.75x)','Normal (1x)'],ans:0,hint:'Deliberately slower.'},
  ];
  let idx = 0;
  for (const s of starters) {
    for (const m of midParts) {
      const e = endings[idx % endings.length];
      const sp = speeds[idx % speeds.length];
      pool.push({
        instruction: `Speak at ${sp.name} speed.`,
        interactionType: 'speaking',
        fields: { textToSpeak: `${s} ${m} ${e}`, options: sp.opt, correctAnswerIndex: sp.ans, hint: sp.hint, targetSpeed: sp.val, phoneticHint: getIpa(`${s} ${m} ${e}`) }
      });
      idx++;
      if (pool.length >= 600) break;
    }
    if (pool.length >= 600) break;
  }
  console.log(`  speedVariance pool: ${pool.length}`);
  return pool;
};

