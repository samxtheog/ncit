const { body, validationResult } = require('express-validator');
const { generateCareerRoadmap, generateLearningPath, generateCareerSuggestions, generateInterestSuggestions } = require('../services/groq.service');

/**
 * POST /api/career/roadmap
 */
const getRoadmap = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ success: false, errors: errors.array() });
  }

  const { careerTitle, faculty, grade, interests, skills, goal } = req.body;

  try {
    const roadmap = await generateCareerRoadmap(
      { faculty, grade, interests, skills, goal },
      careerTitle
    );

    return res.status(200).json({ success: true, roadmap });
  } catch (error) {
    console.error('Groq roadmap error:', error.message);
    console.error('Full error:', error);

    if (error.message.includes('GROQ_API_KEY')) {
      return res.status(500).json({
        success: false,
        message: 'AI service not configured. Add GROQ_API_KEY to .env',
      });
    }

    if (error instanceof SyntaxError) {
      return res.status(500).json({
        success: false,
        message: 'AI returned an unexpected response. Please try again.',
      });
    }

    // Pass through the actual Groq error message for easier debugging
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to generate roadmap. Please try again.',
    });
  }
};

module.exports = { getRoadmap, getLearningPath, getCareerSuggestions, getInterestSuggestions };

/**
 * POST /api/career/learning-path
 */
async function getLearningPath(req, res) {
  const { faculty, grade, interests, skills, goal } = req.body;
  try {
    const result = await generateLearningPath({ faculty, grade, interests, skills, goal });
    return res.status(200).json({ success: true, learningPath: result });
  } catch (error) {
    console.error('LearningPath error:', error.message);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to generate learning path.',
    });
  }
}

/**
 * POST /api/career/suggestions
 */
async function getCareerSuggestions(req, res) {
  const { faculty, grade, interests, skills, goal } = req.body;
  try {
    const result = await generateCareerSuggestions({ faculty, grade, interests, skills, goal });
    return res.status(200).json({ success: true, careers: result.careers });
  } catch (error) {
    console.error('CareerSuggestions error:', error.message);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to generate career suggestions.',
    });
  }
}

/**
 * POST /api/career/interests
 */
async function getInterestSuggestions(req, res) {
  const { faculty, grade } = req.body;
  if (!faculty || !grade) {
    return res.status(422).json({ success: false, message: 'faculty and grade are required.' });
  }
  try {
    const result = await generateInterestSuggestions(faculty, grade);
    return res.status(200).json({ success: true, interests: result.interests });
  } catch (error) {
    console.error('InterestSuggestions error:', error.message);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to generate interest suggestions.',
    });
  }
}
