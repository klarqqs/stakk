import pool from '../config/database.ts';

const MILESTONE_PERCENTAGES = [25, 50, 75, 100];

export interface SavingsGoal {
  id: number;
  user_id: number;
  name: string;
  target_amount: number;
  current_amount: number;
  deadline: string | null;
  auto_save_amount: number | null;
  auto_save_frequency: string | null;
  status: string;
  created_at: Date;
  completed_at: Date | null;
}

export interface GoalContribution {
  id: number;
  goal_id: number;
  user_id: number;
  amount_usdc: number;
  source: string;
  created_at: Date;
}

async function notifyGoalMilestone(
  userId: number,
  goalName: string,
  percentage: number
): Promise<void> {
  try {
    await pool.query(
      `INSERT INTO notifications (user_id, type, title, message)
       VALUES ($1, 'goal_milestone', $2, $3)`,
      [
        userId,
        `Goal milestone: ${goalName}`,
        `You've reached ${percentage}% of your ${goalName} goal!`
      ]
    );
  } catch {
    // Notifications table may not exist yet
  }
}

export async function createGoal(
  userId: number,
  name: string,
  targetAmount: number,
  deadline?: string | null,
  autoSaveAmount?: number | null,
  autoSaveFrequency?: string | null
): Promise<SavingsGoal> {
  if (targetAmount <= 0) {
    throw new Error('Target amount must be positive');
  }

  const result = await pool.query(
    `INSERT INTO savings_goals (user_id, name, target_amount, deadline, auto_save_amount, auto_save_frequency)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [userId, name.trim(), targetAmount, deadline || null, autoSaveAmount ?? null, autoSaveFrequency ?? null]
  );

  return result.rows[0];
}

export async function contributeToGoal(
  userId: number,
  goalId: number,
  amount: number,
  source: string = 'manual'
): Promise<{ goal: SavingsGoal; contribution: GoalContribution }> {
  if (amount <= 0) {
    throw new Error('Contribution amount must be positive');
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const goalResult = await client.query(
      'SELECT * FROM savings_goals WHERE id = $1 AND user_id = $2 AND status = $3 FOR UPDATE',
      [goalId, userId, 'active']
    );

    if (goalResult.rows.length === 0) {
      throw new Error('Goal not found or not active');
    }

    const goal = goalResult.rows[0];
    const walletResult = await client.query(
      'SELECT usdc_balance FROM wallets WHERE user_id = $1 FOR UPDATE',
      [userId]
    );

    if (walletResult.rows.length === 0) {
      throw new Error('Wallet not found');
    }

    const balance = parseFloat(walletResult.rows[0].usdc_balance);
    if (balance < amount) {
      throw new Error('Insufficient USDC balance');
    }

    await client.query(
      'UPDATE wallets SET usdc_balance = usdc_balance - $1, last_synced_at = NOW() WHERE user_id = $2',
      [amount, userId]
    );

    const newCurrent = parseFloat(goal.current_amount) + amount;
    await client.query(
      'UPDATE savings_goals SET current_amount = $1 WHERE id = $2',
      [newCurrent, goalId]
    );

    const contribResult = await client.query(
      `INSERT INTO goal_contributions (goal_id, user_id, amount_usdc, source)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [goalId, userId, amount, source]
    );

    await client.query(
      `INSERT INTO transactions (user_id, type, amount_usdc, status, reference)
       VALUES ($1, 'goal_contribution', $2, 'completed', $3)`,
      [userId, amount, `GOAL-${goalId}-${Date.now()}`]
    );

    await client.query('COMMIT');

    const updatedGoal = await pool.query('SELECT * FROM savings_goals WHERE id = $1', [goalId]);
    const progressBefore = (parseFloat(goal.current_amount) / parseFloat(goal.target_amount)) * 100;
    const progressAfter = (newCurrent / parseFloat(goal.target_amount)) * 100;

    for (const pct of MILESTONE_PERCENTAGES) {
      if (progressBefore < pct && progressAfter >= pct) {
        await notifyGoalMilestone(userId, goal.name, pct);
      }
    }

    if (newCurrent >= parseFloat(goal.target_amount)) {
      await pool.query(
        "UPDATE savings_goals SET status = 'completed', completed_at = NOW() WHERE id = $1",
        [goalId]
      );
      await notifyGoalMilestone(userId, goal.name, 100);
    }

    return {
      goal: updatedGoal.rows[0],
      contribution: contribResult.rows[0]
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function getActiveGoals(userId: number): Promise<SavingsGoal[]> {
  const result = await pool.query(
    `SELECT * FROM savings_goals
     WHERE user_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
}

export async function getGoalById(goalId: number, userId: number): Promise<SavingsGoal | null> {
  const result = await pool.query(
    'SELECT * FROM savings_goals WHERE id = $1 AND user_id = $2',
    [goalId, userId]
  );

  return result.rows[0] ?? null;
}

export async function getGoalContributions(goalId: number, userId: number): Promise<GoalContribution[]> {
  const result = await pool.query(
    `SELECT gc.* FROM goal_contributions gc
     JOIN savings_goals sg ON gc.goal_id = sg.id
     WHERE gc.goal_id = $1 AND sg.user_id = $2
     ORDER BY gc.created_at DESC`,
    [goalId, userId]
  );

  return result.rows;
}

export async function withdrawFromGoal(
  userId: number,
  goalId: number,
  amount: number
): Promise<SavingsGoal> {
  if (amount <= 0) {
    throw new Error('Withdrawal amount must be positive');
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const goalResult = await client.query(
      'SELECT * FROM savings_goals WHERE id = $1 AND user_id = $2 FOR UPDATE',
      [goalId, userId]
    );

    if (goalResult.rows.length === 0) {
      throw new Error('Goal not found');
    }

    const goal = goalResult.rows[0];
    const current = parseFloat(goal.current_amount);
    if (amount > current) {
      throw new Error('Insufficient amount in goal');
    }

    await client.query(
      'UPDATE savings_goals SET current_amount = current_amount - $1 WHERE id = $2',
      [amount, goalId]
    );

    await client.query(
      'UPDATE wallets SET usdc_balance = usdc_balance + $1, last_synced_at = NOW() WHERE user_id = $2',
      [amount, userId]
    );

    await client.query(
      `INSERT INTO transactions (user_id, type, amount_usdc, status, reference)
       VALUES ($1, 'goal_withdrawal', $2, 'completed', $3)`,
      [userId, amount, `GOAL-WD-${goalId}-${Date.now()}`]
    );

    await client.query('COMMIT');

    const updated = await pool.query('SELECT * FROM savings_goals WHERE id = $1', [goalId]);
    return updated.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function deleteGoal(userId: number, goalId: number): Promise<void> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const goalResult = await client.query(
      'SELECT * FROM savings_goals WHERE id = $1 AND user_id = $2 FOR UPDATE',
      [goalId, userId]
    );

    if (goalResult.rows.length === 0) {
      throw new Error('Goal not found');
    }

    const goal = goalResult.rows[0];
    const current = parseFloat(goal.current_amount);

    if (current > 0) {
      await client.query(
        'UPDATE wallets SET usdc_balance = usdc_balance + $1, last_synced_at = NOW() WHERE user_id = $2',
        [current, userId]
      );
    }

    await client.query('DELETE FROM goal_contributions WHERE goal_id = $1', [goalId]);
    await client.query('DELETE FROM savings_goals WHERE id = $1', [goalId]);

    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function processAutoSaveJobs(): Promise<void> {
  const result = await pool.query(
    `SELECT * FROM savings_goals
     WHERE status = 'active'
       AND auto_save_amount IS NOT NULL
       AND auto_save_amount > 0
       AND auto_save_frequency IS NOT NULL`
  );

  const now = new Date();

  for (const goal of result.rows) {
    const freq = goal.auto_save_frequency;
    const lastContrib = await pool.query(
      `SELECT created_at FROM goal_contributions
       WHERE goal_id = $1 AND source = 'auto_save'
       ORDER BY created_at DESC LIMIT 1`,
      [goal.id]
    );

    let shouldRun = false;
    if (lastContrib.rows.length === 0) {
      shouldRun = true;
    } else {
      const last = new Date(lastContrib.rows[0].created_at);
      if (freq === 'daily' && (now.getTime() - last.getTime()) >= 24 * 60 * 60 * 1000) {
        shouldRun = true;
      } else if (freq === 'weekly' && (now.getTime() - last.getTime()) >= 7 * 24 * 60 * 60 * 1000) {
        shouldRun = true;
      } else if (freq === 'monthly' && now.getDate() === 1 && last.getMonth() !== now.getMonth()) {
        shouldRun = true;
      }
    }

    if (shouldRun) {
      try {
        await contributeToGoal(goal.user_id, goal.id, parseFloat(goal.auto_save_amount), 'auto_save');
      } catch (err) {
        console.error('Auto-save failed for goal', goal.id, err);
      }
    }
  }
}

export default {
  createGoal,
  contributeToGoal,
  getActiveGoals,
  getGoalById,
  getGoalContributions,
  withdrawFromGoal,
  deleteGoal,
  processAutoSaveJobs
};
