const Groq = require('groq-sdk');

let _groq = null;

const getGroq = () => {
  if (!_groq) {
    if (!process.env.GROQ_API_KEY) {
      throw new Error('GROQ_API_KEY is not set in environment variables.');
    }
    _groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
  }
  return _groq;
};

/**
 * Generate an AI career roadmap with pros and cons.
 * @param {Object} profile - User profile from setup flow
 * @param {string} careerTitle - Target career title
 * @returns {Object} Parsed roadmap JSON
 */
const generateCareerRoadmap = async (profile, careerTitle) => {
  const prompt = buildPrompt(profile, careerTitle);

  const completion = await getGroq().chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content:
          'You are a career counselor AI for students in Nepal. Always respond with valid JSON only. No markdown, no explanation outside JSON. All salary figures must be in Nepali Rupees (NPR) per month. Job demand must reflect the Nepal job market.',
      },
      { role: 'user', content: prompt },
    ],
    temperature: 0.7,
    max_tokens: 1800,
  });

  const raw = completion.choices[0]?.message?.content ?? '';
  console.log('[Groq raw response]:', raw.slice(0, 300)); // log first 300 chars for debugging

  // Strip any accidental markdown fences or leading text before the JSON
  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new SyntaxError('No JSON object found in Groq response');
  }

  return JSON.parse(jsonMatch[0]);
};

const buildPrompt = (profile, careerTitle) => {
  const faculty    = profile.faculty    || 'General';
  const grade      = profile.grade      || 'Not specified';
  const interests  = profile.interests?.length  ? profile.interests.join(', ')  : 'Not specified';
  const skills     = profile.skills?.length     ? profile.skills.join(', ')     : 'Not specified';
  const goal       = profile.goal       || 'Find a good career';

  return `
A student has the following profile:
- Faculty: ${faculty}
- Grade: ${grade}
- Interests: ${interests}
- Skills: ${skills}
- Goal: ${goal}

Generate a detailed career roadmap for becoming a "${careerTitle}" in the context of Nepal.

Return ONLY a JSON object with this exact structure:
{
  "career": "${careerTitle}",
  "overview": "2-3 sentence summary of this career path",
  "matchReason": "1-2 sentences explaining why this matches the student's profile",
  "steps": [
    {
      "step": 1,
      "title": "Step title",
      "duration": "e.g. 6 months",
      "description": "What to do in this step",
      "resources": ["Resource 1", "Resource 2"]
    }
  ],
  "pros": [
    { "title": "Pro title", "description": "Short explanation" }
  ],
  "cons": [
    { "title": "Con title", "description": "Short explanation" }
  ],
  "salaryRange": "e.g. NPR 30,000 - 80,000/month (realistic Nepal market range)",
  "jobDemand": "High / Medium / Low (based on Nepal job market)",
  "topSkillsNeeded": ["Skill 1", "Skill 2", "Skill 3", "Skill 4"]
}

Rules:
- steps: exactly 5 steps
- pros: exactly 4 items
- cons: exactly 3 items
- topSkillsNeeded: exactly 4 items
- salaryRange must use NPR (Nepali Rupees) per month, reflecting realistic Nepal market rates
- jobDemand must reflect current demand in Nepal (not global figures)
- Keep all text concise and student-friendly
`;
};

// NEB syllabus subjects per faculty
const FACULTY_SUBJECTS = {
  'Science': ['Physics', 'Chemistry', 'Biology', 'Mathematics', 'Computer Science'],
  'Management': ['Business Studies', 'Economics', 'Accountancy', 'Mathematics', 'Marketing'],
  'Humanities': ['English', 'Nepali', 'History', 'Geography', 'Social Studies'],
  'Education': ['Child Development', 'Educational Psychology', 'Pedagogy', 'English', 'Health Education'],
  'Computer Science': ['Programming', 'Data Structures', 'Networking', 'Database Systems', 'Mathematics'],
};

const DEFAULT_SUBJECTS = ['English', 'Mathematics', 'Science', 'Social Studies', 'Computer Basics'];

/**
 * Generate 10 NEB-syllabus MCQ questions for a student.
 */
const generateQuiz = async (profile) => {
  const faculty   = profile.faculty || 'General';
  const grade     = profile.grade   || 'Grade 10';
  const subjects  = FACULTY_SUBJECTS[faculty] || DEFAULT_SUBJECTS;
  // Pick a random subject for today's quiz
  const subject   = subjects[Math.floor(Math.random() * subjects.length)];

  const prompt = `
You are a Nepal NEB (National Examinations Board) exam question generator.

Student profile:
- Faculty: ${faculty}
- Grade: ${grade}
- Subject for today: ${subject}

Generate exactly 10 multiple-choice questions based on the NEB ${faculty} syllabus for ${grade}.
Each question must have exactly 4 options (A, B, C, D) and one correct answer.

Return ONLY a JSON object with this exact structure — no markdown, no explanation:
{
  "subject": "${subject}",
  "grade": "${grade}",
  "faculty": "${faculty}",
  "questions": [
    {
      "id": 1,
      "question": "Question text here?",
      "options": {
        "A": "Option A",
        "B": "Option B",
        "C": "Option C",
        "D": "Option D"
      },
      "correct": "A",
      "explanation": "Brief explanation of the correct answer"
    }
  ]
}

Rules:
- Exactly 10 questions
- Questions must be from the NEB ${faculty} syllabus for ${grade}
- Vary difficulty: 4 easy, 4 medium, 2 hard
- correct must be exactly one of: "A", "B", "C", or "D"
`;

  const completion = await getGroq().chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: 'You are a Nepal NEB exam question generator. Always respond with valid JSON only.',
      },
      { role: 'user', content: prompt },
    ],
    temperature: 0.8,
    max_tokens: 3000,
  });

  const raw = completion.choices[0]?.message?.content ?? '';
  console.log('[Quiz Groq raw]:', raw.slice(0, 200));

  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new SyntaxError('No JSON found in Groq quiz response');

  return JSON.parse(jsonMatch[0]);
};

module.exports = { generateCareerRoadmap, generateQuiz, generateLearningPath, generateCareerSuggestions, generateInterestSuggestions };

/**
 * Generate a personalised 5-step learning path for the user's top career.
 */
async function generateLearningPath(profile) {
  const faculty   = profile.faculty   || 'General';
  const grade     = profile.grade     || 'Not specified';
  const interests = profile.interests?.length ? profile.interests.join(', ') : 'Not specified';
  const skills    = profile.skills?.length    ? profile.skills.join(', ')    : 'Not specified';
  const goal      = profile.goal      || 'Find a good career';

  const prompt = `
A student has this profile:
- Faculty: ${faculty}
- Grade: ${grade}
- Interests: ${interests}
- Skills: ${skills}
- Goal: ${goal}

Generate a personalised 5-step learning path for this student based on their profile and goal.
Each step should be a concrete skill or topic to learn, ordered from beginner to advanced.

Return ONLY a JSON object — no markdown, no explanation:
{
  "steps": [
    {
      "title": "Step title (short, 3-5 words)",
      "subtitle": "One line description of what this covers"
    }
  ]
}

Rules:
- Exactly 5 steps
- Steps must be relevant to the student's faculty, interests, and goal
- Progress naturally from foundational to advanced
- Keep titles concise
`;

  const completion = await getGroq().chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      { role: 'system', content: 'You are a career counselor AI. Always respond with valid JSON only.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.6,
    max_tokens: 600,
  });

  const raw = completion.choices[0]?.message?.content ?? '';
  console.log('[LearningPath Groq raw]:', raw.slice(0, 200));

  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new SyntaxError('No JSON found in Groq learning path response');

  return JSON.parse(jsonMatch[0]);
}

/**
 * Generate 6 personalised career suggestions for the user's profile.
 */
async function generateCareerSuggestions(profile) {
  const faculty   = profile.faculty   || 'General';
  const grade     = profile.grade     || 'Not specified';
  const interests = profile.interests?.length ? profile.interests.join(', ') : 'Not specified';
  const skills    = profile.skills?.length    ? profile.skills.join(', ')    : 'Not specified';
  const goal      = profile.goal      || 'Find a good career';

  const prompt = `
A student has this profile:
- Faculty: ${faculty}
- Grade: ${grade}
- Interests: ${interests}
- Skills: ${skills}
- Goal: ${goal}

Suggest exactly 6 career paths that best match this student's profile.
For each career, provide a match percentage (50-99) based on how well it fits the profile.

Return ONLY a JSON object — no markdown, no explanation:
{
  "careers": [
    {
      "title": "Career Title",
      "match": 92,
      "description": "One sentence description of this career.",
      "category": "technology | business | healthcare | design | education | science | other"
    }
  ]
}

Rules:
- Exactly 6 careers, ordered by match percentage descending
- Careers must be genuinely relevant to the student's faculty, interests, and goal
- match must be a number between 50 and 99
- description must be one concise sentence
- category must be one of the listed values
`;

  const completion = await getGroq().chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      { role: 'system', content: 'You are a career counselor AI for students. Always respond with valid JSON only.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.6,
    max_tokens: 800,
  });

  const raw = completion.choices[0]?.message?.content ?? '';
  console.log('[CareerSuggestions Groq raw]:', raw.slice(0, 300));

  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new SyntaxError('No JSON found in career suggestions response');

  return JSON.parse(jsonMatch[0]);
}

/**
 * Generate interest suggestions for a student based on faculty and grade.
 */
async function generateInterestSuggestions(faculty, grade) {
  const prompt = `
A student has just selected:
- Faculty: ${faculty}
- Grade: ${grade}

They are setting up their profile on a learning platform and need to pick their interests.
Based specifically on what students in ${faculty} at ${grade} level typically study, pursue, and care about,
suggest exactly 10 interest areas that are most relevant and realistic for this student.

These should reflect the actual subjects, career paths, and activities common in ${faculty} education at ${grade} level.
For example, a Humanities Grade 11 student might be interested in Creative Writing, History, Journalism — NOT programming or engineering.

Return ONLY a JSON object — no markdown, no explanation:
{
  "interests": [
    { "name": "Interest Name", "icon": "one of: technology, business, healthcare, design, education, science, arts, law, engineering, media, environment, psychology, finance, sports, government" }
  ]
}

Rules:
- Exactly 10 items
- All interests must be directly relevant to ${faculty} students at ${grade} level
- Names should be concise (2-3 words max)
- No generic interests like "Technology" for a Humanities student unless it's specifically relevant
- Vary the interests — cover different aspects of ${faculty}
`;

  const completion = await getGroq().chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      { role: 'system', content: 'You are a career counselor AI for students. Always respond with valid JSON only. Never suggest interests irrelevant to the student\'s faculty.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.7,
    max_tokens: 400,
  });

  const raw = completion.choices[0]?.message?.content ?? '';
  console.log('[InterestSuggestions Groq raw]:', raw.slice(0, 200));

  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new SyntaxError('No JSON found in interest suggestions response');

  return JSON.parse(jsonMatch[0]);
}
