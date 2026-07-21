const fs = require('fs');
const path = require('path');

const weathers = [
    { name: 'Sunny', emoji: '☀️', funFact: 'The sun is a star located at the center of our solar system!', phonetic: '/ˈsʌn.i/', example: 'It is a sunny day to play outside.' },
    { name: 'Rainy', emoji: '🌧️', funFact: 'Rain is water that falls from the clouds!', phonetic: '/ˈreɪ.ni/', example: 'I need my umbrella because it is rainy.' },
    { name: 'Snowy', emoji: '❄️', funFact: 'Every single snowflake has a unique shape!', phonetic: '/ˈsnoʊ.i/', example: 'We can build a snowman on a snowy day.' },
    { name: 'Cloudy', emoji: '☁️', funFact: 'Clouds are made of tiny water droplets floating in the air!', phonetic: '/ˈklaʊ.di/', example: 'The sky is cloudy and grey today.' },
    { name: 'Windy', emoji: '🌬️', funFact: 'Wind is just moving air caused by the sun heating the Earth.', phonetic: '/ˈwɪn.di/', example: 'Hold your hat on a windy day!' },
    { name: 'Stormy', emoji: '🌩️', funFact: 'Thunder is the sound made by lightning!', phonetic: '/ˈstɔːr.mi/', example: 'The sky gets very dark when it is stormy.' }
];

const professions = [
    { name: 'Doctor', emoji: '👨‍⚕️', funFact: 'Doctors use a stethoscope to listen to your heartbeat!', phonetic: '/ˈdɒk.tər/', example: 'The doctor helps you when you are sick.' },
    { name: 'Teacher', emoji: '👩‍🏫', funFact: 'Teachers help you learn new things every day at school!', phonetic: '/ˈtiː.tʃər/', example: 'My teacher reads books to the class.' },
    { name: 'Police', emoji: '👮', funFact: 'Police officers help keep the neighborhood safe!', phonetic: '/pəˈliːs/', example: 'The police officer helped us cross the street.' },
    { name: 'Firefighter', emoji: '👨‍🚒', funFact: 'Firefighters wear special gear that protects them from extreme heat.', phonetic: '/ˈfaɪərˌfaɪ.tər/', example: 'The firefighter drove the big red truck.' },
    { name: 'Chef', emoji: '👨‍🍳', funFact: 'Chefs wear a tall white hat called a toque!', phonetic: '/ʃef/', example: 'The chef cooked a delicious pizza.' },
    { name: 'Astronaut', emoji: '👨‍🚀', funFact: 'Astronauts float in space because there is very little gravity!', phonetic: '/ˈæs.trə.nɔːt/', example: 'The astronaut flew to the moon in a rocket.' }
];

const generateBatches = (gameType, dataPool) => {
    const dir = path.join('assets/curriculum/kids', gameType);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

    for (let batch = 1; batch <= 20; batch++) {
        const batchData = [];
        const startLevel = (batch - 1) * 10 + 1;
        const endLevel = batch * 10;

        for (let level = startLevel; level <= endLevel; level++) {
            const quests = [];
            for (let q = 1; q <= 3; q++) {
                const item = dataPool[(level + q) % dataPool.length];
                quests.push({
                    id: `KIDS_${gameType.toUpperCase()}_L${level}_Q${q}`,
                    gameType: gameType,
                    level: level,
                    instruction: `Identify the ${gameType}!`,
                    question: item.name,
                    correctAnswer: item.name,
                    hint: `Look closely! What is this?`,
                    emoji: item.emoji,
                    explanation: `Great job, it's ${item.name}!`,
                    funFact: item.funFact,
                    wordExample: item.example,
                    phonetic: item.phonetic
                });
            }
            batchData.push({
                level: level,
                quests: quests
            });
        }
        fs.writeFileSync(path.join(dir, `${gameType}_batch_${batch}.json`), JSON.stringify(batchData, null, 4));
    }
};

generateBatches('weather', weathers);
generateBatches('professions', professions);
console.log('Regenerated batches with rich educational fields!');
