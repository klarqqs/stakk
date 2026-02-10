import { Router } from 'express';
import { StocksController } from '../controllers/stocks.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const controller = new StocksController();

// Public endpoints
router.get('/available', (req, res) => controller.getAvailableStocks(req, res));
router.get('/:ticker', (req, res) => controller.getStockDetails(req, res));

// Protected endpoints (require authentication)
router.post('/buy', authenticateToken, (req, res) => controller.buyStock(req, res));
router.get('/portfolio/mine', authenticateToken, (req, res) => controller.getPortfolio(req, res));
router.get('/wallet', authenticateToken, (req, res) => controller.getWallet(req, res));
router.get('/trades/history', authenticateToken, (req, res) => controller.getTradeHistory(req, res));

export default router;
